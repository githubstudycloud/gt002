# 实施路线图：从0到1的90天计划

> 基于真实项目经验的分阶段实施指南

## 概览

本路线图将全栈项目从概念到生产部署分为4个阶段，每个阶段约20-30天。

```
第一阶段（Day 1-30）：基础搭建
  ↓
第二阶段（Day 31-60）：核心功能开发
  ↓
第三阶段（Day 61-75）：性能优化与测试
  ↓
第四阶段（Day 76-90）：上线准备与部署
```

---

## 第一阶段：基础搭建（Day 1-30）

### Week 1: 技术选型与架构设计

#### Day 1-2: 需求分析与技术调研
**任务**：
- [ ] 梳理核心业务需求
- [ ] 估算初期用户规模（QPS、数据量）
- [ ] 调研竞品技术栈
- [ ] 列出技术选型候选方案

**产出**：
- 需求文档（PRD）
- 技术调研报告

**决策点**：
- 目标用户规模：< 1万 / 1-10万 / 10-100万 / 100万+
- 团队规模：1-3人 / 4-10人 / 10人+
- 预算：有限 / 充足 / 不限

#### Day 3-4: 技术栈选型
**任务**：
- [ ] 确定后端技术栈（参考 [02-technology-selection-guide.md](./02-technology-selection-guide.md)）
- [ ] 确定前端框架
- [ ] 确定数据库方案
- [ ] 确定云平台/部署方案

**推荐方案**：

**初创团队（快速迭代）**：
```
后端: Python/FastAPI 或 Go/Gin
前端: Vue 3 + Vite
数据库: PostgreSQL + Redis
部署: Docker Compose → Kubernetes（成熟后）
云平台: 阿里云/腾讯云（国内）或 AWS（国际）
```

**企业级项目（稳定优先）**：
```
后端: Java/Spring Boot
前端: React + Next.js
数据库: PostgreSQL（主） + MySQL（兼容性）
中间件: Kafka, Redis, Elasticsearch
部署: Kubernetes + Helm
云平台: AWS 或混合云
```

**产出**：
- 技术选型文档
- 架构设计图（参考 [01-architecture-diagrams.md](./01-architecture-diagrams.md)）

#### Day 5-7: 项目结构与开发环境
**任务**：
- [ ] 创建Git仓库（GitHub/GitLab）
- [ ] 设计项目目录结构
- [ ] 配置开发环境（Docker Compose本地环境）
- [ ] 设置CI/CD骨架（GitHub Actions/GitLab CI）
- [ ] 配置代码规范（ESLint/Prettier/Checkstyle）

**项目结构示例（Monorepo）**：
```
project-root/
├── backend/              # 后端服务
│   ├── src/
│   ├── tests/
│   ├── Dockerfile
│   └── requirements.txt (or pom.xml/go.mod)
├── frontend/             # 前端应用
│   ├── src/
│   ├── public/
│   ├── Dockerfile
│   └── package.json
├── infra/                # 基础设施配置
│   ├── docker-compose.yml
│   ├── k8s/
│   └── terraform/
├── docs/                 # 文档
│   ├── api/
│   ├── architecture/
│   └── runbook/
├── scripts/              # 脚本工具
│   ├── deploy.sh
│   └── migrate.sh
├── .github/              # CI/CD配置
│   └── workflows/
└── README.md
```

**产出**：
- 项目骨架
- Docker Compose本地环境
- CI/CD初始配置

### Week 2: 数据库设计与API规范

#### Day 8-10: 数据库设计
**任务**：
- [ ] 设计核心业务表结构
- [ ] 确定主键策略（自增 vs UUID vs 雪花算法）
- [ ] 设计索引方案
- [ ] 考虑分库分表策略（如适用）
- [ ] 编写数据库迁移脚本（Flyway/Liquibase/Alembic）

**设计原则**：
1. 第三范式（3NF）- 消除数据冗余
2. 适当反范式化 - 提高查询性能
3. 为每张表添加：created_at, updated_at, deleted_at（软删除）
4. 使用外键约束（开发环境）vs 应用层维护（生产环境）

**示例表设计**：
```sql
-- 用户表
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_status ON users(status) WHERE deleted_at IS NULL;

-- 订单表（预留分片键）
CREATE TABLE orders (
    id BIGINT PRIMARY KEY,  -- 雪花算法生成
    user_id BIGINT NOT NULL,
    order_no VARCHAR(32) UNIQUE NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_orders_user_id ON orders(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_orders_order_no ON orders(order_no) WHERE deleted_at IS NULL;
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
```

**产出**：
- 数据库ER图
- DDL脚本
- 迁移脚本

#### Day 11-12: API设计
**任务**：
- [ ] 设计RESTful API规范
- [ ] 定义统一响应格式
- [ ] 设计认证授权方案（JWT/OAuth2）
- [ ] 编写API文档（OpenAPI/Swagger）

**RESTful API规范**：
```
GET     /api/v1/users          # 获取用户列表
GET     /api/v1/users/:id      # 获取单个用户
POST    /api/v1/users          # 创建用户
PUT     /api/v1/users/:id      # 更新用户
DELETE  /api/v1/users/:id      # 删除用户
```

**统一响应格式**：
```json
{
  "code": 0,
  "message": "success",
  "data": { ... },
  "timestamp": "2024-01-01T00:00:00Z",
  "request_id": "req-123456"
}

// 错误响应
{
  "code": 40001,
  "message": "User not found",
  "error_detail": "User with id 123 does not exist",
  "timestamp": "2024-01-01T00:00:00Z",
  "request_id": "req-123456"
}
```

**产出**：
- API设计文档
- Swagger/OpenAPI规范文件

#### Day 13-14: 基础设施搭建
**任务**：
- [ ] 搭建开发环境数据库（PostgreSQL/MySQL）
- [ ] 搭建Redis缓存
- [ ] 搭建消息队列（如需要：Kafka/RabbitMQ）
- [ ] 配置Nginx反向代理
- [ ] 搭建监控（Prometheus + Grafana）

**Docker Compose示例**（参考 [03-deployment-devops-guide.md](./03-deployment-devops-guide.md)）：
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: myapp
      POSTGRES_PASSWORD: password
    volumes:
      - postgres-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    ports:
      - "80:80"

volumes:
  postgres-data:
```

**产出**：
- 完整的开发环境
- 基础设施配置文件

### Week 3-4: 核心框架搭建

#### Day 15-21: 后端框架搭建
**任务**：
- [ ] 搭建基础项目结构
- [ ] 配置数据库连接池
- [ ] 实现基础CRUD（用户模块）
- [ ] 实现认证授权（JWT）
- [ ] 集成Redis缓存
- [ ] 实现统一异常处理
- [ ] 实现日志框架（结构化日志）
- [ ] 实现请求追踪（Trace ID）

**代码示例（Spring Boot）**：
```java
// 统一响应格式
@Data
@Builder
public class ApiResponse<T> {
    private int code;
    private String message;
    private T data;
    private String timestamp;
    private String requestId;
}

// 统一异常处理
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiResponse<Void>> handleNotFound(
        ResourceNotFoundException ex,
        HttpServletRequest request
    ) {
        ApiResponse<Void> response = ApiResponse.<Void>builder()
            .code(40004)
            .message(ex.getMessage())
            .timestamp(Instant.now().toString())
            .requestId(request.getHeader("X-Request-ID"))
            .build();

        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleGeneral(
        Exception ex,
        HttpServletRequest request
    ) {
        log.error("Unexpected error", ex);

        ApiResponse<Void> response = ApiResponse.<Void>builder()
            .code(50000)
            .message("Internal server error")
            .timestamp(Instant.now().toString())
            .requestId(request.getHeader("X-Request-ID"))
            .build();

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
}

// 请求追踪
@Component
public class TraceIdFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain filterChain
    ) throws ServletException, IOException {
        String traceId = UUID.randomUUID().toString();
        MDC.put("traceId", traceId);
        response.setHeader("X-Request-ID", traceId);

        try {
            filterChain.doFilter(request, response);
        } finally {
            MDC.clear();
        }
    }
}
```

**产出**：
- 可运行的后端服务
- 基础CRUD API
- 认证授权模块

#### Day 22-28: 前端框架搭建
**任务**：
- [ ] 搭建前端项目（Vite/Create React App）
- [ ] 配置路由（Vue Router/React Router）
- [ ] 配置状态管理（Pinia/Zustand）
- [ ] 集成UI组件库（Element Plus/Ant Design）
- [ ] 实现登录注册页面
- [ ] 实现主布局（导航栏、侧边栏）
- [ ] 配置HTTP客户端（Axios/Fetch）
- [ ] 实现请求拦截（Token注入）

**代码示例（Vue 3）**：
```typescript
// API客户端配置
import axios from 'axios'

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  timeout: 10000,
})

// 请求拦截器（注入Token）
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

// 响应拦截器（统一错误处理）
apiClient.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      // Token过期，跳转登录
      router.push('/login')
    } else if (error.response?.status === 403) {
      message.error('没有权限')
    } else {
      message.error(error.response?.data?.message || '请求失败')
    }
    return Promise.reject(error)
  }
)

// 状态管理（Pinia）
import { defineStore } from 'pinia'

export const useUserStore = defineStore('user', {
  state: () => ({
    userInfo: null,
    token: localStorage.getItem('access_token') || '',
  }),

  actions: {
    async login(username: string, password: string) {
      const data = await apiClient.post('/auth/login', { username, password })
      this.token = data.access_token
      this.userInfo = data.user
      localStorage.setItem('access_token', data.access_token)
    },

    logout() {
      this.token = ''
      this.userInfo = null
      localStorage.removeItem('access_token')
      router.push('/login')
    },
  },
})
```

**产出**：
- 可运行的前端应用
- 登录注册功能
- 基础布局与导航

#### Day 29-30: 集成与联调
**任务**：
- [ ] 前后端联调
- [ ] 解决跨域问题（CORS）
- [ ] 验证完整登录流程
- [ ] 编写集成测试
- [ ] 更新API文档

**产出**：
- 前后端打通的完整流程
- 集成测试用例

---

## 第二阶段：核心功能开发（Day 31-60）

### Week 5-6: 核心业务功能

#### Day 31-42: 业务功能开发
**任务**：
- [ ] 实现核心业务模块（根据需求）
- [ ] 编写单元测试（覆盖率 > 80%）
- [ ] 实现数据校验与业务规则
- [ ] 实现文件上传（如需要）
- [ ] 实现分页查询
- [ ] 实现搜索功能（Elasticsearch）

**开发顺序建议**：
1. 先实现后端API（TDD驱动）
2. 编写单元测试
3. 实现前端页面
4. 编写E2E测试

**产出**：
- 核心业务功能
- 单元测试（覆盖率报告）

### Week 7: 中间件集成

#### Day 43-49: 中间件集成
**任务**：
- [ ] 集成Redis缓存（热点数据）
- [ ] 集成消息队列（异步任务）
- [ ] 集成Elasticsearch（全文搜索）
- [ ] 实现定时任务（如需要）
- [ ] 实现邮件/短信通知

**缓存策略**：
```java
// 热点数据缓存
@Cacheable(value = "products", key = "#id", unless = "#result == null")
public Product getProduct(Long id) {
    return productRepository.findById(id).orElse(null);
}

@CacheEvict(value = "products", key = "#id")
public void updateProduct(Long id, ProductUpdateRequest request) {
    // 更新逻辑
}

// 缓存穿透防护（缓存空对象）
@Cacheable(value = "products", key = "#id")
public Product getProductSafe(Long id) {
    Product product = productRepository.findById(id).orElse(null);
    return product != null ? product : Product.NULL; // 缓存空对象
}
```

**产出**：
- 完整的中间件集成
- 异步任务处理

### Week 8: 安全加固

#### Day 50-56: 安全功能
**任务**：
- [ ] 实现RBAC权限控制
- [ ] 实现API限流（Redis + Lua）
- [ ] 实现敏感数据加密（密码、手机号）
- [ ] 实现审计日志
- [ ] 实现防止SQL注入（参数化查询）
- [ ] 实现防止XSS攻击（输出转义）
- [ ] 实现CSRF防护

**产出**：
- 权限控制系统
- 安全防护机制

### Week 9: 测试与文档

#### Day 57-60: 测试与文档
**任务**：
- [ ] 完善单元测试（覆盖率 > 80%）
- [ ] 编写集成测试
- [ ] 编写E2E测试（Playwright/Cypress）
- [ ] 性能测试（JMeter/K6）
- [ ] 更新API文档（Swagger）
- [ ] 编写开发文档
- [ ] 编写部署文档

**产出**：
- 完整的测试套件
- 齐全的文档

---

## 第三阶段：性能优化与测试（Day 61-75）

### Week 10: 性能优化

#### Day 61-65: 数据库优化
**任务**：
- [ ] 分析慢查询日志
- [ ] 优化SQL（添加索引、重写查询）
- [ ] 实现读写分离
- [ ] 配置数据库连接池
- [ ] 实施数据归档策略

**优化清单**（参考 [04-high-availability-performance.md](./04-high-availability-performance.md)）：
- ✅ 为高频查询字段添加索引
- ✅ 使用EXPLAIN分析查询计划
- ✅ 避免SELECT *
- ✅ 使用批量操作代替单条
- ✅ 配置连接池（HikariCP推荐）

**产出**：
- 数据库优化报告
- 性能提升对比

#### Day 66-70: 应用优化
**任务**：
- [ ] 实现多级缓存（本地 + Redis）
- [ ] 实现异步处理（消息队列）
- [ ] 前端代码分割与懒加载
- [ ] 静态资源CDN加速
- [ ] 启用Gzip压缩
- [ ] JVM参数调优

**产出**：
- 应用性能优化报告

### Week 11: 全面测试

#### Day 71-75: 性能与安全测试
**任务**：
- [ ] 压力测试（目标QPS）
- [ ] 长时间稳定性测试（12小时+）
- [ ] 安全扫描（SAST/DAST）
- [ ] 依赖漏洞扫描（Trivy/Snyk）
- [ ] 灾难恢复演练（备份恢复）

**压力测试目标**：
- QPS: 1000+ (单机)
- P99延迟: < 100ms
- 错误率: < 0.1%
- 内存稳定（无泄漏）

**产出**：
- 性能测试报告
- 安全扫描报告

---

## 第四阶段：上线准备与部署（Day 76-90）

### Week 12: 上线准备

#### Day 76-80: 部署准备
**任务**：
- [ ] 编写Dockerfile（生产级）
- [ ] 编写Kubernetes配置（Deployment/Service/Ingress）
- [ ] 配置CI/CD流水线（完整）
- [ ] 配置监控告警（Prometheus + Grafana）
- [ ] 配置日志收集（ELK/Loki）
- [ ] 配置分布式追踪（Jaeger）
- [ ] 准备回滚方案

**CI/CD流水线**（参考 [03-deployment-devops-guide.md](./03-deployment-devops-guide.md)）：
```
代码提交 → 自动测试 → 安全扫描 → 构建镜像 → 部署测试环境 →
手动审批 → 金丝雀发布（20%） → 观察5分钟 → 全量发布
```

**产出**：
- 完整的部署配置
- CI/CD流水线

#### Day 81-85: 监控与告警
**任务**：
- [ ] 配置Prometheus指标采集
- [ ] 配置Grafana大盘
- [ ] 配置告警规则（高错误率、高延迟、服务不可用）
- [ ] 配置告警通知（企业微信/钉钉/Slack）
- [ ] 配置On-Call轮值

**关键指标**：
- RED指标：Rate, Errors, Duration
- 数据库连接池使用率
- 缓存命中率
- 消息队列积压
- JVM内存与GC

**产出**：
- 完整的监控大盘
- 告警规则

### Week 13: 上线与验证

#### Day 86-87: 灰度发布
**任务**：
- [ ] 部署到生产环境（金丝雀：10%流量）
- [ ] 监控关键指标（30分钟）
- [ ] 扩大到50%流量
- [ ] 监控关键指标（30分钟）
- [ ] 全量发布

**发布清单**：
- ✅ 数据库迁移已执行
- ✅ 配置文件已更新
- ✅ 监控告警已配置
- ✅ 回滚方案已准备
- ✅ 相关团队已通知

**产出**：
- 生产环境运行的应用

#### Day 88-90: 验证与优化
**任务**：
- [ ] 验证核心功能
- [ ] 验证性能指标
- [ ] 查看错误日志
- [ ] 查看监控大盘
- [ ] 根据实际情况调整配置
- [ ] 编写上线报告

**产出**：
- 上线报告
- 优化建议

---

## 持续运营（Day 90+）

### 日常运维

#### 每日检查
- [ ] 查看监控大盘（错误率、延迟）
- [ ] 查看告警（是否有未处理）
- [ ] 查看日志（是否有异常）
- [ ] 查看资源使用（CPU、内存、磁盘）

#### 每周任务
- [ ] 代码审查（Pull Request）
- [ ] 安全扫描（依赖更新）
- [ ] 性能分析（慢查询优化）
- [ ] 备份验证（恢复演练）

#### 每月任务
- [ ] 技术债务梳理
- [ ] 容量规划（资源评估）
- [ ] 故障复盘（Postmortem）
- [ ] 团队分享（技术沉淀）

---

## 关键里程碑

| 阶段 | 时间 | 里程碑 | 验收标准 |
|------|------|--------|----------|
| 第一阶段 | Day 30 | 基础框架完成 | 前后端打通，可运行的原型 |
| 第二阶段 | Day 60 | 核心功能完成 | 业务功能齐全，测试覆盖率 > 80% |
| 第三阶段 | Day 75 | 性能优化完成 | 性能测试达标，安全扫描通过 |
| 第四阶段 | Day 90 | 上线 | 生产环境稳定运行 |

---

## 风险管理

### 常见风险与应对

| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|----------|
| 技术选型错误 | 低 | 高 | 早期充分调研，必要时及时调整 |
| 需求频繁变更 | 高 | 中 | 采用敏捷开发，每周迭代 |
| 性能不达标 | 中 | 高 | 提前性能测试，预留优化时间 |
| 安全漏洞 | 中 | 高 | 集成自动化扫描，定期安全审计 |
| 上线失败 | 低 | 高 | 灰度发布，完善回滚方案 |
| 团队成员离职 | 中 | 中 | 代码规范，文档齐全，知识共享 |

---

## 成功要素

### 技术层面
1. ✅ 合适的技术栈（不追新，不保守）
2. ✅ 清晰的架构设计（简单优先）
3. ✅ 完善的测试（单元+集成+E2E）
4. ✅ 自动化一切（CI/CD、监控、告警）
5. ✅ 可观测性（Metrics、Logging、Tracing）

### 流程层面
1. ✅ 敏捷开发（小步快跑）
2. ✅ 代码审查（至少1人Review）
3. ✅ 文档齐全（代码即文档）
4. ✅ 定期回顾（每周复盘）
5. ✅ 持续优化（技术债务管理）

### 团队层面
1. ✅ 明确分工（但不限于）
2. ✅ 技术分享（知识沉淀）
3. ✅ On-Call轮值（责任共担）
4. ✅ 故障演练（提高响应能力）
5. ✅ 工具投资（提高效率）

---

## 总结

这份90天路线图是一个参考框架，实际项目需要根据具体情况调整：

- **小团队（1-3人）**：可能需要120天，减少中间件，简化架构
- **大团队（10人+）**：可能60天完成，并行开发，专业分工
- **复杂项目**：可能需要180天，分多个迭代，逐步演进

**最重要的原则**：
1. **不要追求完美**：先上线，再优化
2. **关注核心价值**：优先实现MVP（最小可行产品）
3. **保持灵活性**：技术是为业务服务的
4. **持续迭代**：没有一次到位的系统

**记住Linus的话**："Talk is cheap. Show me the code."**

开始你的90天之旅吧！🚀
