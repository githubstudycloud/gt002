const logger = require('./logger')

/**
 * 响应格式转换器 - 在 OpenAI 和 Claude 格式之间转换
 */
class ResponseFormatConverter {
  /**
   * 将 OpenAI chat/completions 格式转换为 Claude messages 格式
   * @param {Object} openaiResponse - OpenAI 格式的响应
   * @returns {Object} Claude 格式的响应
   */
  convertOpenAIToClaude(openaiResponse) {
    try {
      // OpenAI 格式示例:
      // {
      //   "id": "chatcmpl-xxx",
      //   "object": "chat.completion",
      //   "created": 1731456789,
      //   "model": "qwen3-235b",
      //   "choices": [
      //     {
      //       "index": 0,
      //       "message": {
      //         "role": "assistant",
      //         "content": "Hello! How can I help you?"
      //       },
      //       "finish_reason": "stop"
      //     }
      //   ],
      //   "usage": {
      //     "prompt_tokens": 10,
      //     "completion_tokens": 20,
      //     "total_tokens": 30
      //   }
      // }

      if (!openaiResponse.choices || openaiResponse.choices.length === 0) {
        throw new Error('Invalid OpenAI response: no choices found')
      }

      const firstChoice = openaiResponse.choices[0]
      const message = firstChoice.message || {}

      // Claude 格式响应
      const claudeResponse = {
        id: openaiResponse.id || `msg_${Date.now()}`,
        type: 'message',
        role: 'assistant',
        model: openaiResponse.model || 'claude-3-5-sonnet-20241022',
        content: [
          {
            type: 'text',
            text: message.content || ''
          }
        ],
        stop_reason: this._mapFinishReason(firstChoice.finish_reason),
        stop_sequence: null,
        usage: {
          input_tokens: openaiResponse.usage?.prompt_tokens || 0,
          output_tokens: openaiResponse.usage?.completion_tokens || 0
        }
      }

      logger.debug('✅ Converted OpenAI response to Claude format')
      return claudeResponse
    } catch (error) {
      logger.error('❌ Failed to convert OpenAI response to Claude format:', error)
      throw error
    }
  }

  /**
   * 将 Claude messages 请求体转换为 OpenAI chat/completions 格式
   * @param {Object} claudeRequest - Claude 格式的请求
   * @returns {Object} OpenAI 格式的请求
   */
  convertClaudeRequestToOpenAI(claudeRequest) {
    try {
      // Claude 格式示例:
      // {
      //   "model": "claude-sonnet-4-5-20250929",
      //   "max_tokens": 1024,
      //   "messages": [
      //     {
      //       "role": "user",
      //       "content": "Hello"
      //     }
      //   ],
      //   "system": "You are a helpful assistant",
      //   "temperature": 0.7
      // }

      const openaiRequest = {
        model: claudeRequest.model || 'gpt-4',
        messages: []
      }

      // 处理 system 消息
      if (claudeRequest.system) {
        openaiRequest.messages.push({
          role: 'system',
          content: claudeRequest.system
        })
      }

      // 转换 messages
      if (claudeRequest.messages && Array.isArray(claudeRequest.messages)) {
        for (const msg of claudeRequest.messages) {
          const openaiMsg = {
            role: msg.role
          }

          // 处理 content（可能是字符串或数组）
          if (typeof msg.content === 'string') {
            openaiMsg.content = msg.content
          } else if (Array.isArray(msg.content)) {
            // 提取文本内容
            const textContents = msg.content
              .filter((c) => c.type === 'text')
              .map((c) => c.text)
              .join('\n')
            openaiMsg.content = textContents
          }

          openaiRequest.messages.push(openaiMsg)
        }
      }

      // 传递其他参数
      if (claudeRequest.max_tokens !== undefined) {
        openaiRequest.max_tokens = claudeRequest.max_tokens
      }
      if (claudeRequest.temperature !== undefined) {
        openaiRequest.temperature = claudeRequest.temperature
      }
      if (claudeRequest.top_p !== undefined) {
        openaiRequest.top_p = claudeRequest.top_p
      }
      if (claudeRequest.top_k !== undefined) {
        // OpenAI 不支持 top_k，忽略
        logger.debug('⚠️ top_k parameter is not supported in OpenAI format, ignored')
      }
      if (claudeRequest.stream !== undefined) {
        openaiRequest.stream = claudeRequest.stream
      }

      logger.debug('✅ Converted Claude request to OpenAI format')
      return openaiRequest
    } catch (error) {
      logger.error('❌ Failed to convert Claude request to OpenAI format:', error)
      throw error
    }
  }

  /**
   * 映射 finish_reason
   * OpenAI: stop, length, content_filter, tool_calls, function_call
   * Claude: end_turn, max_tokens, stop_sequence, tool_use
   */
  _mapFinishReason(openaiFinishReason) {
    const mapping = {
      stop: 'end_turn',
      length: 'max_tokens',
      content_filter: 'end_turn',
      tool_calls: 'tool_use',
      function_call: 'tool_use'
    }
    return mapping[openaiFinishReason] || 'end_turn'
  }

  /**
   * 转换流式响应的单个 chunk
   * @param {string} openaiChunk - OpenAI SSE 格式的 chunk (data: {...})
   * @returns {string} Claude SSE 格式的 chunk
   */
  convertOpenAIStreamChunkToClaude(openaiChunk) {
    try {
      // 移除 "data: " 前缀
      if (!openaiChunk.startsWith('data: ')) {
        return openaiChunk // 不是数据行，直接返回
      }

      const jsonStr = openaiChunk.substring(6).trim()

      // [DONE] 标记
      if (jsonStr === '[DONE]') {
        return 'event: message_stop\ndata: {"type":"message_stop"}\n'
      }

      const openaiData = JSON.parse(jsonStr)

      // OpenAI stream chunk 格式:
      // {
      //   "id": "chatcmpl-xxx",
      //   "object": "chat.completion.chunk",
      //   "created": 1731456789,
      //   "model": "qwen3-235b",
      //   "choices": [
      //     {
      //       "index": 0,
      //       "delta": {
      //         "role": "assistant",
      //         "content": "Hello"
      //       },
      //       "finish_reason": null
      //     }
      //   ]
      // }

      if (!openaiData.choices || openaiData.choices.length === 0) {
        return '' // 空 chunk
      }

      const choice = openaiData.choices[0]
      const delta = choice.delta || {}

      let claudeEvents = []

      // 消息开始事件
      if (delta.role === 'assistant' && !delta.content) {
        claudeEvents.push({
          type: 'message_start',
          message: {
            id: openaiData.id || `msg_${Date.now()}`,
            type: 'message',
            role: 'assistant',
            model: openaiData.model || 'claude-3-5-sonnet-20241022',
            content: [],
            usage: { input_tokens: 0, output_tokens: 0 }
          }
        })
        claudeEvents.push({
          type: 'content_block_start',
          index: 0,
          content_block: { type: 'text', text: '' }
        })
      }

      // 内容 delta
      if (delta.content) {
        claudeEvents.push({
          type: 'content_block_delta',
          index: 0,
          delta: { type: 'text_delta', text: delta.content }
        })
      }

      // 完成事件
      if (choice.finish_reason) {
        claudeEvents.push({
          type: 'content_block_stop',
          index: 0
        })
        claudeEvents.push({
          type: 'message_delta',
          delta: { stop_reason: this._mapFinishReason(choice.finish_reason), stop_sequence: null },
          usage: { output_tokens: 0 }
        })
      }

      // 转换为 SSE 格式
      return claudeEvents
        .map((event) => `event: ${event.type}\ndata: ${JSON.stringify(event)}\n`)
        .join('\n')
    } catch (error) {
      logger.error('❌ Failed to convert OpenAI stream chunk:', error)
      return openaiChunk // 转换失败，返回原始数据
    }
  }

  /**
   * 检测响应是否为 OpenAI 格式
   * @param {Object} response - 响应对象
   * @returns {boolean}
   */
  isOpenAIFormat(response) {
    return (
      response &&
      (response.object === 'chat.completion' || response.object === 'chat.completion.chunk') &&
      Array.isArray(response.choices)
    )
  }

  /**
   * 检测响应是否为 Claude 格式
   * @param {Object} response - 响应对象
   * @returns {boolean}
   */
  isClaudeFormat(response) {
    return response && response.type === 'message' && response.role === 'assistant'
  }
}

module.exports = new ResponseFormatConverter()
