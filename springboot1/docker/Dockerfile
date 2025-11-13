# 多阶段构建Dockerfile

# 第一阶段: 构建应用
FROM maven:3.9-eclipse-temurin-17 AS builder

# 设置工作目录
WORKDIR /build

# 复制pom文件并下载依赖(利用Docker缓存)
COPY pom.xml .
COPY common/pom.xml common/
COPY gateway/pom.xml gateway/
COPY auth/pom.xml auth/
COPY system/system-api/pom.xml system/system-api/
COPY system/system-dao/pom.xml system/system-dao/
COPY system/system-biz/pom.xml system/system-biz/
COPY user/user-api/pom.xml user/user-api/
COPY user/user-dao/pom.xml user/user-dao/
COPY user/user-biz/pom.xml user/user-biz/
COPY order/order-api/pom.xml order/order-api/
COPY order/order-dao/pom.xml order/order-dao/
COPY order/order-biz/pom.xml order/order-biz/
COPY product/product-api/pom.xml product/product-api/
COPY product/product-dao/pom.xml product/product-dao/
COPY product/product-biz/pom.xml product/product-biz/

# 下载依赖
RUN mvn dependency:go-offline -B

# 复制源代码
COPY common common
COPY gateway gateway
COPY auth auth
COPY system system
COPY user user
COPY order order
COPY product product

# 构建应用
ARG MODULE_NAME
RUN mvn clean package -DskipTests -pl ${MODULE_NAME} -am

# 第二阶段: 运行应用
FROM eclipse-temurin:17-jre-alpine

# 安装必要工具
RUN apk add --no-cache curl tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apk del tzdata

# 创建应用目录
WORKDIR /app

# 创建非root用户
RUN addgroup -g 1000 spring && \
    adduser -D -u 1000 -G spring spring

# 复制jar文件
ARG MODULE_NAME
COPY --from=builder /build/${MODULE_NAME}/target/*.jar app.jar

# 设置JVM参数
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/logs/heapdump.hprof"

# Spring Boot配置
ARG SPRING_PROFILES_ACTIVE=prod
ENV SPRING_PROFILES_ACTIVE=${SPRING_PROFILES_ACTIVE}

# 创建日志目录
RUN mkdir -p /app/logs && \
    chown -R spring:spring /app

# 切换到非root用户
USER spring:spring

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# 暴露端口
EXPOSE 8080

# 启动应用
ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -Djava.security.egd=file:/dev/./urandom -jar app.jar"]
