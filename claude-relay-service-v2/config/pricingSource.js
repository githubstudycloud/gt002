// ⚠️ 内网部署配置：默认禁用外网价格数据下载
// 直接使用本地 fallback 文件 (resources/model-pricing/model_prices_and_context_window.json)
// 如需启用外网下载，设置环境变量 ENABLE_PRICE_MIRROR=true

const ENABLE_PRICE_MIRROR = process.env.ENABLE_PRICE_MIRROR === 'true'

const repository =
  process.env.PRICE_MIRROR_REPO || process.env.GITHUB_REPOSITORY || 'Wei-Shaw/claude-relay-service'
const branch = process.env.PRICE_MIRROR_BRANCH || 'price-mirror'
const pricingFileName = process.env.PRICE_MIRROR_FILENAME || 'model_prices_and_context_window.json'
const hashFileName = process.env.PRICE_MIRROR_HASH_FILENAME || 'model_prices_and_context_window.sha256'

const baseUrl = process.env.PRICE_MIRROR_BASE_URL
  ? process.env.PRICE_MIRROR_BASE_URL.replace(/\/$/, '')
  : `https://raw.githubusercontent.com/${repository}/${branch}`

module.exports = {
  // 禁用外网下载（内网部署默认）
  enablePriceMirror: ENABLE_PRICE_MIRROR,
  pricingFileName,
  hashFileName,
  pricingUrl: ENABLE_PRICE_MIRROR
    ? process.env.PRICE_MIRROR_JSON_URL || `${baseUrl}/${pricingFileName}`
    : null,
  hashUrl: ENABLE_PRICE_MIRROR
    ? process.env.PRICE_MIRROR_HASH_URL || `${baseUrl}/${hashFileName}`
    : null
}
