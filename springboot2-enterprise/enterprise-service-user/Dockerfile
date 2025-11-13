# 多阶段构建 - 第一阶段：构建
FROM maven:3.8.6-openjdk-8-slim AS builder

WORKDIR /build

# 复制 pom 文件并下载依赖（利用 Docker 缓存）
COPY pom.xml .
COPY enterprise-common/pom.xml enterprise-common/
COPY enterprise-core/pom.xml enterprise-core/
COPY enterprise-service-user/pom.xml enterprise-service-user/

RUN mvn dependency:go-offline -B

# 复制源代码
COPY enterprise-common enterprise-common
COPY enterprise-core enterprise-core
COPY enterprise-service-user enterprise-service-user

# 构建项目
RUN mvn clean package -DskipTests -pl enterprise-service-user -am

# 多阶段构建 - 第二阶段：运行
FROM openjdk:8-jre-alpine

# 设置时区
RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apk del tzdata

# 创建应用目录
WORKDIR /app

# 从构建阶段复制 jar 包
COPY --from=builder /build/enterprise-service-user/target/enterprise-service-user-*.jar app.jar

# 创建日志目录
RUN mkdir -p /app/logs

# 设置 JVM 参数
ENV JAVA_OPTS="-server -Xms512m -Xmx1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -XX:+ParallelRefProcEnabled -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/logs/heapdump.hprof"

# 暴露端口
EXPOSE 8081

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8081/actuator/health || exit 1

# 启动应用
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
