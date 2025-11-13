package com.enterprise.common.result;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 统一响应状态码
 */
@Getter
@AllArgsConstructor
public enum ResultCode {

    /**
     * 成功
     */
    SUCCESS(200, "操作成功"),

    /**
     * 失败
     */
    FAILED(500, "操作失败"),

    /**
     * 参数错误
     */
    VALIDATE_FAILED(400, "参数校验失败"),

    /**
     * 未认证
     */
    UNAUTHORIZED(401, "未认证或认证已过期"),

    /**
     * 无权限
     */
    FORBIDDEN(403, "无权限访问"),

    /**
     * 资源不存在
     */
    NOT_FOUND(404, "请求的资源不存在"),

    /**
     * 请求方法不支持
     */
    METHOD_NOT_ALLOWED(405, "请求方法不支持"),

    /**
     * 系统内部错误
     */
    INTERNAL_SERVER_ERROR(500, "系统内部错误"),

    /**
     * 服务不可用
     */
    SERVICE_UNAVAILABLE(503, "服务不可用"),

    /**
     * 业务异常
     */
    BUSINESS_ERROR(600, "业务异常"),

    /**
     * 远程调用失败
     */
    REMOTE_CALL_FAILED(601, "远程服务调用失败"),

    /**
     * 数据库操作失败
     */
    DATABASE_ERROR(602, "数据库操作失败"),

    /**
     * 缓存操作失败
     */
    CACHE_ERROR(603, "缓存操作失败"),

    /**
     * 限流
     */
    RATE_LIMIT(429, "请求过于频繁，请稍后再试");

    private final Integer code;
    private final String message;
}
