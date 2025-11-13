# 微服务开发指南

## 项目结构

### 标准微服务结构

```
user-service/
├── src/
│   ├── main/
│   │   ├── java/com/enterprise/user/
│   │   │   ├── UserServiceApplication.java
│   │   │   ├── config/              # 配置类
│   │   │   ├── controller/          # REST 控制器
│   │   │   ├── service/             # 业务逻辑层
│   │   │   ├── repository/          # 数据访问层
│   │   │   ├── domain/              # 领域模型
│   │   │   │   ├── entity/         # 实体类
│   │   │   │   ├── dto/            # 数据传输对象
│   │   │   │   └── vo/             # 值对象
│   │   │   ├── exception/           # 异常处理
│   │   │   ├── event/               # 事件发布/订阅
│   │   │   ├── mapper/              # 对象映射
│   │   │   └── util/                # 工具类
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       ├── application-prod.yml
│   │       └── db/migration/        # Flyway 迁移脚本
│   └── test/
│       ├── java/
│       │   ├── integration/         # 集成测试
│       │   └── unit/                # 单元测试
│       └── resources/
└── pom.xml
```

## 领域驱动设计 (DDD)

### 分层架构

```
Presentation Layer (Controller)
         ↓
Application Layer (Service)
         ↓
Domain Layer (Entity, Value Object, Domain Service)
         ↓
Infrastructure Layer (Repository, External Service)
```

### 实体 (Entity)

```java
@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String username;

    @Column(nullable = false)
    private String email;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Enumerated(EnumType.STRING)
    private UserStatus status;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    // 领域方法
    public void activate() {
        if (this.status == UserStatus.INACTIVE) {
            this.status = UserStatus.ACTIVE;
            this.updatedAt = LocalDateTime.now();
        }
    }

    public boolean isActive() {
        return this.status == UserStatus.ACTIVE;
    }
}
```

### 值对象 (Value Object)

```java
@Embeddable
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Address {

    @Column(name = "street")
    private String street;

    @Column(name = "city")
    private String city;

    @Column(name = "state")
    private String state;

    @Column(name = "zip_code")
    private String zipCode;

    @Column(name = "country")
    private String country;

    public String getFullAddress() {
        return String.format("%s, %s, %s %s, %s",
            street, city, state, zipCode, country);
    }
}
```

### DTO (Data Transfer Object)

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDTO {

    private Long id;

    @NotBlank(message = "Username is required")
    @Size(min = 3, max = 50)
    private String username;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    private String status;
    private LocalDateTime createdAt;
}
```

### Mapper (使用 MapStruct)

```java
@Mapper(componentModel = "spring")
public interface UserMapper {

    UserDTO toDTO(User user);

    User toEntity(UserDTO dto);

    List<UserDTO> toDTOList(List<User> users);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    void updateEntityFromDTO(UserDTO dto, @MappingTarget User user);
}
```

## Controller 层

### REST API 设计

```java
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Validated
@Tag(name = "User Management", description = "User management APIs")
public class UserController {

    private final UserService userService;

    @GetMapping
    @Operation(summary = "Get all users", description = "Retrieve a paginated list of users")
    public ResponseEntity<Page<UserDTO>> getAllUsers(
            @PageableDefault(size = 20, sort = "id", direction = Sort.Direction.DESC) Pageable pageable) {
        return ResponseEntity.ok(userService.getAllUsers(pageable));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get user by ID")
    public ResponseEntity<UserDTO> getUserById(@PathVariable Long id) {
        return ResponseEntity.ok(userService.getUserById(id));
    }

    @PostMapping
    @Operation(summary = "Create a new user")
    public ResponseEntity<UserDTO> createUser(@Valid @RequestBody UserDTO userDTO) {
        UserDTO created = userService.createUser(userDTO);
        return ResponseEntity
            .created(URI.create("/api/v1/users/" + created.getId()))
            .body(created);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update user")
    public ResponseEntity<UserDTO> updateUser(
            @PathVariable Long id,
            @Valid @RequestBody UserDTO userDTO) {
        return ResponseEntity.ok(userService.updateUser(id, userDTO));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete user")
    public void deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
    }

    @PatchMapping("/{id}/activate")
    @Operation(summary = "Activate user")
    public ResponseEntity<UserDTO> activateUser(@PathVariable Long id) {
        return ResponseEntity.ok(userService.activateUser(id));
    }
}
```

### 统一响应格式

```java
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ApiResponse<T> {

    private boolean success;
    private String message;
    private T data;
    private String timestamp;
    private String path;

    public static <T> ApiResponse<T> success(T data) {
        return ApiResponse.<T>builder()
            .success(true)
            .message("Success")
            .data(data)
            .timestamp(LocalDateTime.now().toString())
            .build();
    }

    public static <T> ApiResponse<T> error(String message) {
        return ApiResponse.<T>builder()
            .success(false)
            .message(message)
            .timestamp(LocalDateTime.now().toString())
            .build();
    }
}
```

## Service 层

```java
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;
    private final UserEventPublisher eventPublisher;
    private final CacheManager cacheManager;

    @Override
    public Page<UserDTO> getAllUsers(Pageable pageable) {
        log.debug("Fetching all users with pagination: {}", pageable);
        return userRepository.findAll(pageable)
            .map(userMapper::toDTO);
    }

    @Override
    @Cacheable(value = "users", key = "#id")
    public UserDTO getUserById(Long id) {
        log.debug("Fetching user by id: {}", id);
        return userRepository.findById(id)
            .map(userMapper::toDTO)
            .orElseThrow(() -> new UserNotFoundException("User not found with id: " + id));
    }

    @Override
    @Transactional
    @CacheEvict(value = "users", allEntries = true)
    public UserDTO createUser(UserDTO userDTO) {
        log.info("Creating new user: {}", userDTO.getUsername());

        // 业务验证
        if (userRepository.existsByUsername(userDTO.getUsername())) {
            throw new DuplicateUserException("Username already exists");
        }

        User user = userMapper.toEntity(userDTO);
        user.setStatus(UserStatus.ACTIVE);
        User savedUser = userRepository.save(user);

        // 发布事件
        eventPublisher.publishUserCreated(savedUser);

        return userMapper.toDTO(savedUser);
    }

    @Override
    @Transactional
    @CacheEvict(value = "users", key = "#id")
    public UserDTO updateUser(Long id, UserDTO userDTO) {
        log.info("Updating user with id: {}", id);

        User user = userRepository.findById(id)
            .orElseThrow(() -> new UserNotFoundException("User not found"));

        userMapper.updateEntityFromDTO(userDTO, user);
        User updatedUser = userRepository.save(user);

        eventPublisher.publishUserUpdated(updatedUser);

        return userMapper.toDTO(updatedUser);
    }

    @Override
    @Transactional
    @CacheEvict(value = "users", key = "#id")
    public void deleteUser(Long id) {
        log.info("Deleting user with id: {}", id);

        if (!userRepository.existsById(id)) {
            throw new UserNotFoundException("User not found");
        }

        userRepository.deleteById(id);
        eventPublisher.publishUserDeleted(id);
    }

    @Override
    @Transactional
    public UserDTO activateUser(Long id) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new UserNotFoundException("User not found"));

        user.activate();  // 领域方法
        User activatedUser = userRepository.save(user);

        return userMapper.toDTO(activatedUser);
    }
}
```

## Repository 层

```java
@Repository
public interface UserRepository extends JpaRepository<User, Long>, JpaSpecificationExecutor<User> {

    Optional<User> findByUsername(String username);

    boolean existsByUsername(String username);

    List<User> findByStatus(UserStatus status);

    @Query("SELECT u FROM User u WHERE u.email = :email")
    Optional<User> findByEmail(@Param("email") String email);

    @Query("SELECT u FROM User u WHERE u.createdAt >= :startDate AND u.createdAt <= :endDate")
    List<User> findUsersCreatedBetween(
        @Param("startDate") LocalDateTime startDate,
        @Param("endDate") LocalDateTime endDate);
}
```

### 动态查询 (Specification)

```java
public class UserSpecifications {

    public static Specification<User> hasUsername(String username) {
        return (root, query, cb) ->
            username == null ? null : cb.equal(root.get("username"), username);
    }

    public static Specification<User> hasStatus(UserStatus status) {
        return (root, query, cb) ->
            status == null ? null : cb.equal(root.get("status"), status);
    }

    public static Specification<User> createdAfter(LocalDateTime date) {
        return (root, query, cb) ->
            date == null ? null : cb.greaterThanOrEqualTo(root.get("createdAt"), date);
    }
}

// 使用
Specification<User> spec = Specification.where(UserSpecifications.hasUsername(username))
    .and(UserSpecifications.hasStatus(status))
    .and(UserSpecifications.createdAfter(startDate));

List<User> users = userRepository.findAll(spec);
```

## 异常处理

### 自定义异常

```java
public class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(String message) {
        super(message);
    }
}

public class DuplicateUserException extends RuntimeException {
    public DuplicateUserException(String message) {
        super(message);
    }
}
```

### 全局异常处理器

```java
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public ApiResponse<?> handleUserNotFound(UserNotFoundException ex, WebRequest request) {
        log.error("User not found: {}", ex.getMessage());
        return ApiResponse.error(ex.getMessage())
            .path(request.getDescription(false));
    }

    @ExceptionHandler(DuplicateUserException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    public ApiResponse<?> handleDuplicateUser(DuplicateUserException ex) {
        return ApiResponse.error(ex.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiResponse<?> handleValidationExceptions(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach(error -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });
        return ApiResponse.builder()
            .success(false)
            .message("Validation failed")
            .data(errors)
            .build();
    }

    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public ApiResponse<?> handleGlobalException(Exception ex) {
        log.error("Unexpected error", ex);
        return ApiResponse.error("An unexpected error occurred");
    }
}
```

## 事件驱动

### 事件定义

```java
@Data
@Builder
@AllArgsConstructor
public class UserCreatedEvent {
    private Long userId;
    private String username;
    private String email;
    private LocalDateTime timestamp;
}
```

### 事件发布

```java
@Component
@RequiredArgsConstructor
@Slf4j
public class UserEventPublisher {

    private final KafkaTemplate<String, Object> kafkaTemplate;
    private static final String TOPIC = "user-events";

    public void publishUserCreated(User user) {
        UserCreatedEvent event = UserCreatedEvent.builder()
            .userId(user.getId())
            .username(user.getUsername())
            .email(user.getEmail())
            .timestamp(LocalDateTime.now())
            .build();

        kafkaTemplate.send(TOPIC, "user.created", event);
        log.info("Published user created event: {}", event);
    }

    public void publishUserUpdated(User user) {
        // 类似实现
    }

    public void publishUserDeleted(Long userId) {
        // 类似实现
    }
}
```

### 事件监听

```java
@Component
@Slf4j
public class UserEventListener {

    @KafkaListener(topics = "user-events", groupId = "notification-service")
    public void handleUserCreated(UserCreatedEvent event) {
        log.info("Received user created event: {}", event);
        // 发送欢迎邮件等
    }
}
```

## 缓存策略

### Redis 缓存配置

```java
@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public CacheManager cacheManager(RedisConnectionFactory connectionFactory) {
        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofMinutes(10))
            .serializeKeysWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new StringRedisSerializer()))
            .serializeValuesWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new GenericJackson2JsonRedisSerializer()))
            .disableCachingNullValues();

        return RedisCacheManager.builder(connectionFactory)
            .cacheDefaults(config)
            .transactionAware()
            .build();
    }
}
```

### 缓存注解使用

```java
@Cacheable(value = "users", key = "#id")  // 查询时缓存
@CachePut(value = "users", key = "#result.id")  // 更新时更新缓存
@CacheEvict(value = "users", key = "#id")  // 删除时清除缓存
@CacheEvict(value = "users", allEntries = true)  // 清除所有缓存
```

## 测试

### 单元测试

```java
@SpringBootTest
@AutoConfigureMockMvc
class UserServiceTest {

    @MockBean
    private UserRepository userRepository;

    @Autowired
    private UserService userService;

    @Test
    void testCreateUser() {
        UserDTO dto = UserDTO.builder()
            .username("testuser")
            .email("test@example.com")
            .build();

        User user = new User();
        user.setId(1L);
        user.setUsername(dto.getUsername());

        when(userRepository.save(any(User.class))).thenReturn(user);

        UserDTO result = userService.createUser(dto);

        assertNotNull(result);
        assertEquals("testuser", result.getUsername());
        verify(userRepository, times(1)).save(any(User.class));
    }
}
```

### 集成测试 (Testcontainers)

```java
@SpringBootTest
@Testcontainers
@AutoConfigureMockMvc
class UserControllerIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
        .withDatabaseName("testdb")
        .withUsername("test")
        .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    private MockMvc mockMvc;

    @Test
    void testCreateUser() throws Exception {
        String userJson = """
            {
                "username": "testuser",
                "email": "test@example.com"
            }
            """;

        mockMvc.perform(post("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(userJson))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.username").value("testuser"));
    }
}
```

## API 文档

### SpringDoc OpenAPI 配置

```java
@Configuration
public class OpenAPIConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("Enterprise User Service API")
                .version("1.0.0")
                .description("User management microservice")
                .contact(new Contact()
                    .name("Enterprise Team")
                    .email("team@enterprise.com")))
            .components(new Components()
                .addSecuritySchemes("bearer-jwt",
                    new SecurityScheme()
                        .type(SecurityScheme.Type.HTTP)
                        .scheme("bearer")
                        .bearerFormat("JWT")));
    }
}
```

访问: http://localhost:8080/swagger-ui.html

## 最佳实践

1. **单一职责原则** - 每个类只负责一件事
2. **依赖注入** - 使用构造器注入而非字段注入
3. **不可变对象** - DTO 使用 `@Builder` 和 `final` 字段
4. **事务管理** - 在 Service 层使用 `@Transactional`
5. **异常处理** - 使用自定义异常和全局异常处理器
6. **日志记录** - 使用 SLF4J,记录关键操作
7. **验证** - 使用 Bean Validation 注解
8. **分页** - 使用 `Pageable` 和 `Page`
9. **版本控制** - API 路径包含版本号 `/api/v1/`
10. **文档** - 使用 OpenAPI 注解生成文档

## 下一步

- 学习 [安全认证](security-guide.md)
- 了解 [性能优化](performance-tuning.md)
- 查看 [代码规范](coding-standards.md)
