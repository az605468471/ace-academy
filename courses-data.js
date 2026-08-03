// ========================================
// 王牌学院 · 课程库数据（数据驱动）
// 以后加方向：在 DIRECTIONS 里加一段即可
// 加课程：在对应方向的 courses 里加
// ========================================

const DIRECTIONS = {
    ai: {
        name: 'AI应用',
        nameEn: 'AI Application',
        icon: 'ph-robot',
        desc: 'ChatGPT · AI绘画 · AI视频',
        descEn: 'ChatGPT · AI Art · AI Video',
        courses: [
            {name:'AI人人通 — 什么是AI', nameEn:'AI Essentials', dur:'3小时', durEn:'3h', level:'入门', levelEn:'Beginner', src:'https://www.bilibili.com/video/BV1uNk1YxEJQ/', type:'video', srcName:'B站'},
            {name:'ChatGPT实战 — 提示词', nameEn:'ChatGPT Practice', dur:'4小时', durEn:'4h', level:'进阶', levelEn:'Intermediate', src:'https://www.bilibili.com/video/BV1FvXLYSEQj/', type:'video', srcName:'B站'},
            {name:'AI做图片 — MJ/SD', nameEn:'AI Image Creation', dur:'3小时', durEn:'3h', level:'进阶', levelEn:'Intermediate', src:'https://www.bilibili.com/video/BV1RL4y1T7qK/', type:'video', srcName:'B站'},
            {name:'AI做视频 — 剪映AI', nameEn:'AI Video CapCut', dur:'3小时', durEn:'3h', level:'进阶', levelEn:'Intermediate', src:'https://www.bilibili.com/video/BV1KJYrz4Epm/', type:'video', srcName:'B站'},
            {name:'AI办公 — PPT/Excel', nameEn:'AI Office Tools', dur:'4小时', durEn:'4h', level:'进阶', levelEn:'Intermediate', src:'https://www.bilibili.com/video/BV1xwVr6FEh4/', type:'video', srcName:'B站'},
        ]
    },
    block: {
        name: '区块链/Web3',
        nameEn: 'Blockchain/Web3',
        icon: 'ph-currency-btc',
        desc: '钱包 · DeFi · 智能合约',
        descEn: 'Wallet · DeFi · Contracts',
        courses: [
            {name:'区块链入门 — 比特币', nameEn:'Blockchain Basics', dur:'3小时', durEn:'3h', level:'入门', levelEn:'Beginner', src:'https://www.bilibili.com/video/BV1RL4y1T7qK/', type:'video', srcName:'B站'},
            {name:'钱包使用 — MetaMask', nameEn:'MetaMask Wallet', dur:'2小时', durEn:'2h', level:'入门', levelEn:'Beginner', src:'https://www.bilibili.com/video/BV1RL4y1T7qK/', type:'video', srcName:'B站'},
            {name:'DeFi基础', nameEn:'DeFi Basics', dur:'3小时', durEn:'3h', level:'进阶', levelEn:'Intermediate', src:'https://learnblockchain.cn/courses', type:'learn', srcName:'登链'},
            {name:'智能合约 — Solidity', nameEn:'Smart Contracts', dur:'5小时', durEn:'5h', level:'高级', levelEn:'Advanced', src:'https://learnblockchain.cn/article/4376', type:'learn', srcName:'登链'},
            {name:'NFT与数字资产', nameEn:'NFT & Assets', dur:'3小时', durEn:'3h', level:'进阶', levelEn:'Intermediate', src:'https://learnblockchain.cn/courses', type:'learn', srcName:'登链'},
        ]
    },
    ecom: {
        name: '跨境电商',
        nameEn: 'E-commerce',
        icon: 'ph-storefront',
        desc: '亚马逊 · Shopee · TikTok',
        descEn: 'Amazon · Shopee · TikTok',
        courses: [
            {name:'跨境电商入门', nameEn:'E-commerce Basics', dur:'3小时', durEn:'3h', level:'入门', levelEn:'Beginner', src:'https://www.bilibili.com/video/BV1RYqHYnEw8/', type:'video', srcName:'B站'},
            {name:'选品策略', nameEn:'Product Selection', dur:'3小时', durEn:'3h', level:'进阶', levelEn:'Intermediate', src:'https://www.bilibili.com/video/BV1qG4y1s7G3/', type:'video', srcName:'B站'},
            {name:'店铺运营', nameEn:'Store Operations', dur:'4小时', durEn:'4h', level:'进阶', levelEn:'Intermediate', src:'https://www.bilibili.com/video/BV1jM4y1w7Fj/', type:'video', srcName:'B站'},
            {name:'物流与支付', nameEn:'Logistics & Payment', dur:'2小时', durEn:'2h', level:'入门', levelEn:'Beginner', src:'https://www.bilibili.com/video/BV1RYqHYnEw8/', type:'video', srcName:'B站'},
            {name:'TikTok带货', nameEn:'TikTok Commerce', dur:'4小时', durEn:'4h', level:'进阶', levelEn:'Intermediate', src:'https://www.bilibili.com/video/BV1jM4y1w7Fj/', type:'video', srcName:'B站'},
        ]
    },
    mkt: {
        name: '数字营销',
        nameEn: 'Digital Marketing',
        icon: 'ph-megaphone',
        desc: '社媒 · 内容 · 私域',
        descEn: 'Social · Content · Private',
        courses: [
            {name:'营销思维', nameEn:'Marketing Thinking', dur:'3小时', durEn:'3h', level:'入门', levelEn:'Beginner', src:'https://www.coursera.org/courses?query=digital+marketing', type:'learn', srcName:'Coursera'},
            {name:'社交媒体运营', nameEn:'Social Media', dur:'4小时', durEn:'4h', level:'进阶', levelEn:'Intermediate', src:'https://www.bilibili.com/video/BV1uNk1YxEJQ/', type:'video', srcName:'B站'},
            {name:'内容创作', nameEn:'Content Creation', dur:'3小时', durEn:'3h', level:'进阶', levelEn:'Intermediate', src:'https://www.bilibili.com/video/BV1FvXLYSEQj/', type:'video', srcName:'B站'},
            {name:'私域流量', nameEn:'Private Traffic', dur:'3小时', durEn:'3h', level:'进阶', levelEn:'Intermediate', src:'https://www.bilibili.com/video/BV1qG4y1s7G3/', type:'video', srcName:'B站'},
            {name:'数据分析', nameEn:'Data Analysis', dur:'4小时', durEn:'4h', level:'高级', levelEn:'Advanced', src:'https://www.coursera.org/courses?query=data+analytics', type:'learn', srcName:'Coursera'},
        ]
    },
    code: {
        name: '编程开发',
        nameEn: 'Programming',
        icon: 'ph-code',
        desc: 'Python · 网页 · AI编程',
        descEn: 'Python · Web · AI Coding',
        courses: [
            {name:'编程思维', nameEn:'Programming Mindset', dur:'3小时', durEn:'3h', level:'入门', levelEn:'Beginner', src:'https://www.khanacademy.org/computing', type:'learn', srcName:'可汗'},
            {name:'Python基础', nameEn:'Python Basics', dur:'5小时', durEn:'5h', level:'进阶', levelEn:'Intermediate', src:'https://www.bilibili.com/video/BV1Jgf6YvE8e/', type:'video', srcName:'B站'},
            {name:'网页制作', nameEn:'Web Development', dur:'5小时', durEn:'5h', level:'进阶', levelEn:'Intermediate', src:'https://www.freecodecamp.org/chinese/', type:'learn', srcName:'freeCodeCamp'},
            {name:'AI辅助编程', nameEn:'AI Coding', dur:'3小时', durEn:'3h', level:'进阶', levelEn:'Intermediate', src:'https://www.bilibili.com/video/BV1xwVr6FEh4/', type:'video', srcName:'B站'},
            {name:'项目实战', nameEn:'Project Practice', dur:'6小时', durEn:'6h', level:'高级', levelEn:'Advanced', src:'https://www.freecodecamp.org/chinese/', type:'learn', srcName:'freeCodeCamp'},
        ]
    },
    // ====== 以后在这里加新方向 ======
    // finance: {
    //     name: '理财投资',
    //     icon: 'ph-chart-line',
    //     desc: '...',
    //     courses: [...]
    // }
};

// 学历教育进阶认证体系
const EDUCATION_LEVELS = [
    {level:'micro', name:'微证书', nameEn:'Micro-cert', credit:5, desc:'完成单门课，掌握基础技能', descEn:'Complete a course, master basic skill'},
    {level:'direction', name:'方向证书', nameEn:'Direction Cert', credit:20, desc:'完成一个方向5门课', descEn:'Complete one direction (5 courses)'},
    {level:'advanced', name:'进阶认证', nameEn:'Advanced Cert', credit:null, desc:'多方向+项目+论文', descEn:'Multiple directions + project + thesis'},
    {level:'degree', name:'学历衔接', nameEn:'Degree Track', credit:null, desc:'对接高校/行业认证', descEn:'Connect to university/industry cert'},
];
