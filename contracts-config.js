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
        ACE:      '0x9AE0A6301347cFDa0074B9598A1b2C2f0eEDB6b5',
        Course:   '0xf3dEa9374Ba3Dd553D8B863c9De5ff32F548C0Aa',
        Referral: '0xc7C5431353B83908d56841F4288b417bBCd32c66',
        Lock:     '0x0f03dcBD35262954aAD74D963Acb01b9F8439B79',
        Market:   '0x0fEcaC154b3C10cdB56e32d8106873f438c71E06',
        Cert:     '0xd5AaC5e1c450F884983Ffd1F959A9dfE9cFde493'
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
