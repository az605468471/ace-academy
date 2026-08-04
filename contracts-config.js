// ============================================
// 王牌学院 ACE Academy - 合约配置 (BSC 主网)
// 所有合约地址（已部署并验证，owner=资金钱包②）
// 警告：绝不要在此文件存放任何私钥
// ============================================

const CONTRACT_CONFIG = {
    network: {
        name: 'BSC Mainnet',
        chainId: 56,
        rpc: 'https://bsc-dataseed1.binance.org',
        symbol: 'BNB',
        explorer: 'https://bscscan.com'
    },
    usdt: '0x55d398326f99059fF775485246999027B3197955',
    contracts: {
        ACE:      '0xF48B6221acF1265Efb54e5225FefedE244180CD8',
        Course:   '0xC83011b964774Bd4463AB7Bc5936a1eEF9eF50E0',
        Referral: '0xcDFC71567933146970BC8bBb68F094D19c20f52a',
        Lock:     '0x6F48ba794C06975121F44dc184D4D29b6cB9Bf27',
        Market:   '0xF36b2AAD44322FD6726EFFD7B10884ce93201112',
        Cert:     '0x79C8F7f2469dC4cC2c4C2EcD3a0e8616a676c53B'
    },
    // 钱包地址
    wallets: {
        deployer:   '0xcbB8c62C2155A9eec61Dd5107A9827E3ccC21738',
        ownerFund:  '0x0CF51a12d81019Ef823B52196c3c7841aF7A6671',
        charity:    '0x133638070aEb48c8fB34FEdfcE3060B834029236',
        platform:   '0x470107129B0d247672De6fc14246544AFD49dA6D',
        pool:       '0x225E956272eC20C2eBAE91D38851a6Fb21B99240',
        promo:      '0x5450f7617b074a2C2c935fD6Ce51eA46b17c2A4E'
    }
};
