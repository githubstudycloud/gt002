package com.enterprise.common.core.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

/**
 * 统一返回结果
 *
 * @param <T> 数据类型
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Result<T> implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 状态码
     */
    private Integer code;

    /**
     * 消息
     */
    private String message;

    /**
     * 数据
     */
    private T data;

    /**
     * 时间戳
     */
    private Long timestamp;

    /**
     * 成功返回
     */
    public static <T> Result<T> success() {
        return success(null);
    }

    /**
     * 成功返回
     *
     * @param data 数据
     */
    public static <T> Result<T> success(T data) {
        return success("操作成功", data);
    }

    /**
     * 成功返回
     *
     * @param message 消息
     * @param data    数据
     */
    public static <T> Result<T> success(String message, T data) {
        return new Result<>(200, message, data, System.currentTimeMillis());
    }

    /**
     * 失败返回
     */
    public static <T> Result<T> error() {
        return error("操作失败");
    }

    /**
     * 失败返回
     *
     * @param message 消息
     */
    public static <T> Result<T> error(String message) {
        return error(500, message);
    }

    /**
     * 失败返回
     *
     * @param code    状态码
     * @param message 消息
     */
    public static <T> Result<T> error(Integer code, String message) {
        return new Result<>(code, message, null, System.currentTimeMillis());
    }
}
