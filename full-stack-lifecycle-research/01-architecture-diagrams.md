# 全栈架构图谱 (Mermaid Diagrams)

## 1. 完整开发生命周期流程

```mermaid
graph TB
    Start([项目启动]) --> A1[技术选型]
    A1 --> A2[架构设计]
    A2 --> A3[环境准备]

    A3 --> B1[开发阶段]
    B1 --> B2[代码审查]
    B2 --> B3[自动化测试]
    B3 --> B4{测试通过?}
    B4 -->|否| B1
    B4 -->|是| C1[构建打包]

    C1 --> C2[镜像构建]
    C2 --> C3[安全扫描]
    C3 --> C4{扫描通过?}
    C4 -->|否| B1
    C4 -->|是| D1[部署到测试环境]

    D1 --> D2[集成测试]
    D2 --> D3[性能测试]
    D3 --> D4{测试通过?}
    D4 -->|否| B1
    D4 -->|是| E1[部署到预发布]

    E1 --> E2[灰度发布]
    E2 --> E3[监控指标]
    E3 --> E4{监控正常?}
    E4 -->|否| E5[自动回滚]
    E5 --> F1[问题分析]
    F1 --> B1

    E4 -->|是| E6[扩大灰度]
    E6 --> E7[全量发布]
    E7 --> G1[生产监控]
    G1 --> G2[日志分析]
    G2 --> G3[性能优化]
    G3 --> End([持续迭代])
```

## 2. 技术栈选型决策树

```mermaid
graph TD
    Start([技术选型]) --> A1{项目类型?}

    A1 -->|企业级应用| B1[后端: Java/Spring Boot]
    A1 -->|高性能服务| B2[后端: Go/Rust]
    A1 -->|快速原型| B3[后端: Python/FastAPI]
    A1 -->|微服务| B4[后端: 多语言混合]

    B1 --> C1{前端需求?}
    B2 --> C1
    B3 --> C1
    B4 --> C1

    C1 -->|后台管理| D1[Vue 3 + Element Plus]
    C1 -->|用户端产品| D2[React + Next.js]
    C1 -->|高性能渲染| D3[React + 虚拟列表]
    C1 -->|多团队协作| D4[微前端架构]

    D1 --> E1{数据库选型}
    D2 --> E1
    D3 --> E1
    D4 --> E1

    E1 -->|复杂关系| F1[PostgreSQL]
    E1 -->|高并发读写| F2[MySQL + Redis]
    E1 -->|文档型数据| F3[MongoDB]
    E1 -->|分析型| F4[ClickHouse]
    E1 -->|分布式| F5[TiDB/CockroachDB]

    F1 --> G1[部署平台选择]
    F2 --> G1
    F3 --> G1
    F4 --> G1
    F5 --> G1

    G1 -->|小团队| H1[Docker Compose]
    G1 -->|中型团队| H2[Kubernetes]
    G1 -->|无运维需求| H3[云托管服务]
    G1 -->|混合部署| H4[多云架构]
```

## 3. 微服务架构全景图

```mermaid
graph TB
    subgraph "客户端层"
        Web[Web浏览器]
        Mobile[移动应用]
        IoT[IoT设备]
    end

    subgraph "接入层"
        CDN[CDN]
        DNS[DNS解析]
        LB[负载均衡器]
        Gateway[API网关]
    end

    subgraph "业务服务层"
        UserSvc[用户服务]
        OrderSvc[订单服务]
        PaymentSvc[支付服务]
        ProductSvc[商品服务]
        NotifySvc[通知服务]
    end

    subgraph "中间件层"
        MQ[消息队列<br/>Kafka/RabbitMQ]
        Cache[分布式缓存<br/>Redis Cluster]
        Registry[服务注册中心<br/>Consul/Nacos]
        Config[配置中心<br/>Apollo/Nacos]
    end

    subgraph "数据层"
        MySQL[(MySQL<br/>主从集群)]
        MongoDB[(MongoDB<br/>副本集)]
        ES[(Elasticsearch)]
        S3[(对象存储<br/>S3/OSS)]
    end

    subgraph "可观测性"
        Prometheus[Prometheus]
        Grafana[Grafana]
        Jaeger[Jaeger]
        ELK[ELK Stack]
    end

    Web --> CDN
    Mobile --> LB
    IoT --> Gateway
    CDN --> Gateway
    LB --> Gateway

    Gateway --> UserSvc
    Gateway --> OrderSvc
    Gateway --> PaymentSvc
    Gateway --> ProductSvc

    UserSvc --> Registry
    OrderSvc --> Registry
    PaymentSvc --> Registry
    ProductSvc --> Registry
    NotifySvc --> Registry

    UserSvc --> Config
    OrderSvc --> Config

    UserSvc --> Cache
    OrderSvc --> MQ
    PaymentSvc --> MQ
    NotifySvc --> MQ

    UserSvc --> MySQL
    OrderSvc --> MySQL
    PaymentSvc --> MySQL
    ProductSvc --> MongoDB
    ProductSvc --> ES
    ProductSvc --> S3

    UserSvc -.监控.-> Prometheus
    OrderSvc -.监控.-> Prometheus
    Prometheus --> Grafana

    UserSvc -.追踪.-> Jaeger
    OrderSvc -.追踪.-> Jaeger

    UserSvc -.日志.-> ELK
    OrderSvc -.日志.-> ELK
```

## 4. CI/CD流水线架构

```mermaid
graph LR
    subgraph "代码阶段"
        A1[开发提交代码] --> A2[Git Push]
        A2 --> A3[Webhook触发]
    end

    subgraph "CI阶段"
        A3 --> B1[代码检出]
        B1 --> B2[依赖安装]
        B2 --> B3[代码检查<br/>Lint/Format]
        B3 --> B4[单元测试]
        B4 --> B5[代码覆盖率]
        B5 --> B6[安全扫描<br/>SAST]
        B6 --> B7[构建制品]
    end

    subgraph "镜像阶段"
        B7 --> C1[构建Docker镜像]
        C1 --> C2[镜像扫描<br/>Trivy]
        C2 --> C3[推送到Registry]
    end

    subgraph "CD阶段-测试环境"
        C3 --> D1[部署到测试环境]
        D1 --> D2[健康检查]
        D2 --> D3[集成测试]
        D3 --> D4[E2E测试]
        D4 --> D5{测试通过?}
        D5 -->|否| D6[通知失败]
        D5 -->|是| E1[部署到预发布]
    end

    subgraph "CD阶段-生产环境"
        E1 --> E2[手动审批]
        E2 --> E3[金丝雀发布<br/>5%流量]
        E3 --> E4[监控指标]
        E4 --> E5{指标正常?}
        E5 -->|否| E6[自动回滚]
        E5 -->|是| E7[扩大到50%]
        E7 --> E8[监控指标]
        E8 --> E9{指标正常?}
        E9 -->|否| E6
        E9 -->|是| E10[全量发布]
    end

    E10 --> F1[生产监控]
    F1 --> F2[日志收集]
    F2 --> F3[告警通知]
```

## 5. 数据库分库分表架构

```mermaid
graph TB
    subgraph "应用层"
        App1[应用实例1]
        App2[应用实例2]
        App3[应用实例3]
    end

    subgraph "分库分表中间件"
        Proxy[ShardingSphere-Proxy]
        Router[路由规则引擎]
    end

    subgraph "数据库集群1"
        DB1Master[(DB1-Master<br/>用户0-99999)]
        DB1Slave1[(DB1-Slave1)]
        DB1Slave2[(DB1-Slave2)]
    end

    subgraph "数据库集群2"
        DB2Master[(DB2-Master<br/>用户100000-199999)]
        DB2Slave1[(DB2-Slave1)]
        DB2Slave2[(DB2-Slave2)]
    end

    subgraph "数据库集群3"
        DB3Master[(DB3-Master<br/>用户200000-299999)]
        DB3Slave1[(DB3-Slave1)]
        DB3Slave2[(DB3-Slave2)]
    end

    subgraph "缓存层"
        RedisCluster[Redis Cluster]
    end

    App1 --> Proxy
    App2 --> Proxy
    App3 --> Proxy

    Proxy --> Router

    Router -->|写操作| DB1Master
    Router -->|写操作| DB2Master
    Router -->|写操作| DB3Master

    Router -->|读操作| DB1Slave1
    Router -->|读操作| DB1Slave2
    Router -->|读操作| DB2Slave1
    Router -->|读操作| DB2Slave2
    Router -->|读操作| DB3Slave1
    Router -->|读操作| DB3Slave2

    DB1Master -->|主从复制| DB1Slave1
    DB1Master -->|主从复制| DB1Slave2
    DB2Master -->|主从复制| DB2Slave1
    DB2Master -->|主从复制| DB2Slave2
    DB3Master -->|主从复制| DB3Slave1
    DB3Master -->|主从复制| DB3Slave2

    App1 --> RedisCluster
    App2 --> RedisCluster
    App3 --> RedisCluster
```

## 6. 高可用架构设计

```mermaid
graph TB
    subgraph "多地域部署"
        subgraph "Region1-主"
            AZ1A[可用区1A]
            AZ1B[可用区1B]
            AZ1C[可用区1C]
        end

        subgraph "Region2-备"
            AZ2A[可用区2A]
            AZ2B[可用区2B]
        end
    end

    subgraph "流量接入"
        DNS[DNS解析]
        GSLB[全局负载均衡]
    end

    subgraph "应用层"
        App1[应用集群1<br/>AZ1A]
        App2[应用集群2<br/>AZ1B]
        App3[应用集群3<br/>AZ1C]
        App4[应用集群4<br/>AZ2A]
    end

    subgraph "数据层"
        DB1[(主数据库<br/>AZ1A)]
        DB2[(备数据库<br/>AZ1B)]
        DB3[(异地备份<br/>AZ2A)]
    end

    DNS --> GSLB
    GSLB -->|主流量| AZ1A
    GSLB -->|主流量| AZ1B
    GSLB -->|主流量| AZ1C
    GSLB -.故障切换.-> AZ2A

    AZ1A --> App1
    AZ1B --> App2
    AZ1C --> App3
    AZ2A --> App4

    App1 --> DB1
    App2 --> DB1
    App3 --> DB1
    App4 -.读取.-> DB3

    DB1 -->|同步复制| DB2
    DB1 -->|异步复制| DB3

    DB1 -.心跳检测.-> DB2
    DB2 -.自动故障转移.-> DB1
```

## 7. 监控告警体系

```mermaid
graph TB
    subgraph "数据源"
        App[应用服务]
        Infra[基础设施]
        DB[数据库]
        MQ[消息队列]
        Cache[缓存]
    end

    subgraph "数据采集"
        AppExporter[应用Exporter]
        NodeExporter[Node Exporter]
        DBExporter[DB Exporter]
        MQExporter[MQ Exporter]
        Filebeat[Filebeat]
        Jaeger[Jaeger Agent]
    end

    subgraph "存储与处理"
        Prometheus[Prometheus]
        ES[Elasticsearch]
        JaegerCollector[Jaeger Collector]
    end

    subgraph "可视化"
        Grafana[Grafana Dashboard]
        Kibana[Kibana]
        JaegerUI[Jaeger UI]
    end

    subgraph "告警"
        AlertManager[AlertManager]
        Rules[告警规则引擎]
    end

    subgraph "通知渠道"
        Email[邮件]
        WeCom[企业微信]
        Slack[Slack]
        PagerDuty[PagerDuty]
    end

    App --> AppExporter
    Infra --> NodeExporter
    DB --> DBExporter
    MQ --> MQExporter

    AppExporter --> Prometheus
    NodeExporter --> Prometheus
    DBExporter --> Prometheus
    MQExporter --> Prometheus

    App --> Filebeat
    Filebeat --> ES

    App --> Jaeger
    Jaeger --> JaegerCollector

    Prometheus --> Grafana
    ES --> Kibana
    JaegerCollector --> JaegerUI

    Prometheus --> Rules
    Rules --> AlertManager

    AlertManager --> Email
    AlertManager --> WeCom
    AlertManager --> Slack
    AlertManager --> PagerDuty
```

## 8. 安全防护架构

```mermaid
graph TB
    subgraph "外部威胁"
        Hacker[攻击者]
        Bot[恶意爬虫]
    end

    subgraph "边界防护"
        WAF[Web应用防火墙]
        DDoS[DDoS防护]
        AntiBot[反爬虫]
    end

    subgraph "接入层安全"
        SSL[SSL/TLS加密]
        RateLimit[流量限制]
        IPWhitelist[IP白名单]
    end

    subgraph "应用层安全"
        Auth[认证中心<br/>OAuth2/JWT]
        RBAC[权限控制<br/>RBAC/ABAC]
        InputValid[输入验证]
        OutputEncode[输出编码]
    end

    subgraph "数据层安全"
        Encryption[数据加密]
        Desensitize[敏感数据脱敏]
        Audit[审计日志]
    end

    subgraph "密钥管理"
        Vault[密钥管理系统<br/>HashiCorp Vault]
        KMS[云密钥服务<br/>AWS KMS]
    end

    subgraph "安全扫描"
        SAST[静态代码扫描]
        DAST[动态安全测试]
        ImageScan[镜像漏洞扫描]
        DependScan[依赖漏洞扫描]
    end

    Hacker --> WAF
    Bot --> AntiBot
    WAF --> DDoS
    DDoS --> SSL
    AntiBot --> RateLimit

    SSL --> Auth
    RateLimit --> Auth
    IPWhitelist --> Auth

    Auth --> RBAC
    RBAC --> InputValid
    InputValid --> OutputEncode

    OutputEncode --> Encryption
    Encryption --> Desensitize
    Desensitize --> Audit

    Encryption --> Vault
    Vault --> KMS

    SAST -.扫描.-> InputValid
    DAST -.扫描.-> Auth
    ImageScan -.扫描.-> OutputEncode
    DependScan -.扫描.-> InputValid
```

## 9. 配置管理与推送

```mermaid
graph TB
    subgraph "配置管理平台"
        ConfigUI[配置管理界面]
        ConfigAPI[配置API]
        ConfigDB[(配置数据库)]
        VersionControl[版本控制]
        Approval[审批流程]
    end

    subgraph "配置中心"
        ConfigServer[配置服务器<br/>Apollo/Nacos]
        Cache[配置缓存]
    end

    subgraph "推送机制"
        LongPoll[长轮询]
        WebSocket[WebSocket]
        SSE[Server-Sent Events]
    end

    subgraph "应用集群"
        App1[应用实例1]
        App2[应用实例2]
        App3[应用实例3]
        AppN[应用实例N]
    end

    subgraph "灰度发布"
        GrayRule[灰度规则引擎]
        TargetGroup[目标分组]
    end

    subgraph "监控与回滚"
        Monitor[配置变更监控]
        Rollback[一键回滚]
    end

    ConfigUI --> Approval
    Approval --> ConfigAPI
    ConfigAPI --> ConfigDB
    ConfigAPI --> VersionControl

    ConfigAPI --> ConfigServer
    ConfigServer --> Cache

    ConfigServer --> LongPoll
    ConfigServer --> WebSocket
    ConfigServer --> SSE

    LongPoll --> App1
    WebSocket --> App2
    SSE --> App3
    LongPoll --> AppN

    ConfigAPI --> GrayRule
    GrayRule --> TargetGroup
    TargetGroup --> App1
    TargetGroup --> App2

    App1 --> Monitor
    App2 --> Monitor
    App3 --> Monitor
    AppN --> Monitor

    Monitor --> Rollback
    Rollback --> ConfigServer
```

## 10. 全链路压测架构

```mermaid
graph TB
    subgraph "压测发起"
        TestPlan[压测计划]
        Scenarios[压测场景]
        DataPrepare[测试数据准备]
    end

    subgraph "流量生成"
        JMeter[JMeter]
        Gatling[Gatling]
        K6[K6]
        Locust[Locust]
    end

    subgraph "流量标记"
        Shadow[影子流量标记]
        TrafficSplit[流量分流]
    end

    subgraph "生产环境"
        Gateway[网关]
        App[应用服务]
        Cache[缓存]
        MQ[消息队列]
    end

    subgraph "影子库"
        ShadowDB[(影子数据库)]
        ShadowCache[(影子缓存)]
        ShadowMQ[(影子队列)]
    end

    subgraph "实时监控"
        Metrics[性能指标]
        Response[响应时间]
        TPS[TPS/QPS]
        Error[错误率]
    end

    subgraph "分析报告"
        Report[压测报告]
        Bottleneck[瓶颈分析]
        Optimization[优化建议]
    end

    TestPlan --> Scenarios
    Scenarios --> DataPrepare

    DataPrepare --> JMeter
    DataPrepare --> Gatling
    DataPrepare --> K6
    DataPrepare --> Locust

    JMeter --> Shadow
    Gatling --> Shadow
    K6 --> Shadow
    Locust --> Shadow

    Shadow --> TrafficSplit
    TrafficSplit --> Gateway

    Gateway --> App
    App -->|正常流量| Cache
    App -->|正常流量| MQ
    App -->|影子流量| ShadowDB
    App -->|影子流量| ShadowCache
    App -->|影子流量| ShadowMQ

    App --> Metrics
    Metrics --> Response
    Metrics --> TPS
    Metrics --> Error

    Response --> Report
    TPS --> Report
    Error --> Report

    Report --> Bottleneck
    Bottleneck --> Optimization
```

## 11. 日志处理与归档

```mermaid
graph LR
    subgraph "日志源"
        App[应用日志]
        Access[访问日志]
        Error[错误日志]
        Audit[审计日志]
    end

    subgraph "采集层"
        Filebeat[Filebeat]
        Fluentd[Fluentd]
    end

    subgraph "处理层"
        Logstash[Logstash]
        Parser[日志解析]
        Filter[过滤器]
        Enrich[日志增强]
    end

    subgraph "存储层-热数据"
        ES[Elasticsearch<br/>7天热数据]
    end

    subgraph "存储层-温数据"
        ESWarm[Elasticsearch<br/>30天温数据]
    end

    subgraph "存储层-冷数据"
        S3[对象存储<br/>长期归档]
    end

    subgraph "查询分析"
        Kibana[Kibana]
        Grafana[Grafana Loki]
    end

    subgraph "告警"
        ElastAlert[ElastAlert]
    end

    App --> Filebeat
    Access --> Filebeat
    Error --> Fluentd
    Audit --> Fluentd

    Filebeat --> Logstash
    Fluentd --> Logstash

    Logstash --> Parser
    Parser --> Filter
    Filter --> Enrich

    Enrich --> ES
    ES -->|7天后| ESWarm
    ESWarm -->|30天后| S3

    ES --> Kibana
    ES --> Grafana
    ES --> ElastAlert
```

## 12. 故障恢复流程

```mermaid
graph TB
    Start([服务异常]) --> Detect{异常检测}

    Detect -->|健康检查失败| A1[标记实例不健康]
    Detect -->|错误率飙升| A2[触发告警]
    Detect -->|响应时间超时| A3[记录追踪信息]

    A1 --> B1{自动恢复?}
    A2 --> B1
    A3 --> B1

    B1 -->|是| C1[自动重启实例]
    B1 -->|否| C2[人工介入]

    C1 --> C3[健康检查]
    C3 --> C4{恢复成功?}
    C4 -->|是| D1[恢复流量]
    C4 -->|否| C5[标记失败]

    C5 --> C6{重试次数?}
    C6 -->|未超限| C1
    C6 -->|已超限| E1[熔断降级]

    E1 --> E2[返回降级响应]
    E2 --> E3[通知运维团队]
    E3 --> C2

    C2 --> F1[查看日志]
    F1 --> F2[分析追踪]
    F2 --> F3[定位根因]

    F3 --> G1{需要回滚?}
    G1 -->|是| G2[执行回滚]
    G1 -->|否| G3[修复代码]

    G2 --> G4[验证回滚]
    G3 --> G5[推送修复]

    G4 --> H1[恢复服务]
    G5 --> H1

    H1 --> H2[监控指标]
    H2 --> H3{服务正常?}
    H3 -->|是| I1[解除告警]
    H3 -->|否| F1

    I1 --> I2[事故复盘]
    I2 --> I3[优化改进]
    I3 --> End([完成])

    D1 --> End
```

## 13. 版本发布策略对比

```mermaid
graph TB
    subgraph "蓝绿部署"
        BG1[蓝环境<br/>当前版本]
        BG2[绿环境<br/>新版本]
        BG3[切换流量]
        BG4[快速回滚]

        BG1 --> BG3
        BG2 --> BG3
        BG3 --> BG4
    end

    subgraph "金丝雀发布"
        C1[1%流量]
        C2[监控指标]
        C3[10%流量]
        C4[监控指标]
        C5[50%流量]
        C6[100%流量]

        C1 --> C2
        C2 --> C3
        C3 --> C4
        C4 --> C5
        C5 --> C6
    end

    subgraph "滚动更新"
        R1[更新Pod1]
        R2[健康检查]
        R3[更新Pod2]
        R4[健康检查]
        R5[更新Pod N]

        R1 --> R2
        R2 --> R3
        R3 --> R4
        R4 --> R5
    end

    subgraph "灰度发布"
        G1[按地域灰度]
        G2[按用户灰度]
        G3[按特性灰度]
        G4[Feature Toggle]

        G1 --> G4
        G2 --> G4
        G3 --> G4
    end

    Start([发布计划]) --> Choice{选择策略}

    Choice -->|零停机| BG1
    Choice -->|渐进式| C1
    Choice -->|K8s原生| R1
    Choice -->|精细控制| G1
```

## 14. 技术债务管理

```mermaid
graph TB
    Start([识别技术债务]) --> A1[代码质量扫描]
    A1 --> A2[依赖版本检查]
    A1 --> A3[性能分析]
    A1 --> A4[安全漏洞扫描]

    A2 --> B1{债务等级}
    A3 --> B1
    A4 --> B1

    B1 -->|P0-严重| C1[立即修复]
    B1 -->|P1-高| C2[本迭代修复]
    B1 -->|P2-中| C3[规划修复]
    B1 -->|P3-低| C4[待排期]

    C1 --> D1[创建任务]
    C2 --> D1
    C3 --> D1
    C4 --> D1

    D1 --> E1[评估影响范围]
    E1 --> E2[制定修复计划]
    E2 --> E3[开发与测试]
    E3 --> E4[灰度发布]
    E4 --> E5[监控验证]

    E5 --> F1{修复成功?}
    F1 -->|是| F2[关闭任务]
    F1 -->|否| E2

    F2 --> G1[更新文档]
    G1 --> G2[团队分享]
    G2 --> G3[预防措施]
    G3 --> End([持续改进])
```

---

## 总结

这些Mermaid图表覆盖了全栈开发的关键架构决策点：

1. **完整生命周期**：从开发到部署到运维的闭环
2. **技术选型决策树**：帮助快速做出技术栈选择
3. **微服务架构**：展示现代分布式系统的全貌
4. **CI/CD流水线**：自动化交付的完整流程
5. **数据库架构**：分库分表与高可用设计
6. **监控告警**：完整的可观测性体系
7. **安全防护**：多层次的安全架构
8. **配置管理**：动态配置的推送与回滚
9. **压测架构**：全链路性能测试
10. **日志处理**：从采集到归档的完整链路
11. **故障恢复**：自动化故障处理流程
12. **发布策略**：多种发布模式的对比
13. **技术债务**：系统化的债务管理流程

每个图表都可以作为实际项目的参考架构，根据具体业务场景进行调整和优化。
