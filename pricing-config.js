// ============================================
// 王牌学院 ACE Academy - 价格体系配置（唯一权威来源）
// 当前模式：固定 200U / 方向（后续如需三档，另做）
// 重要：前端所有价格展示与支付必须引用本文件，避免前后端脱节
// ============================================

const PRICING = {
    // 当前定价：每方向固定 200U
    directionPrice: 200,
    // 初始 ACE 汇率 (合约 acePrice = 0.01 USDT/ACE)
    aceInitialPrice: 0.01,
    // 默认推荐人(官方推广钱包)
    defaultReferrer: (typeof CONTRACT_CONFIG !== 'undefined') ? CONTRACT_CONFIG.wallets.promo : '',
    // 预留：未来三档套餐（暂不用，保持200U固定）
    _packages: {
        single: { price: 200, aceBonus: 2000 },
        direction: { price: 200, aceBonus: 2000 },
        supreme: { price: 200, aceBonus: 2000 }
    }
};
