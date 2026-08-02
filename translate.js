// 页面内容翻译器 - 在页面加载后执行
function translatePage() {
    const lang = localStorage.getItem('ace_lang') || 'zh';
    if (lang === 'zh') return; // 中文不需要翻译
    
    const T = {
        en: {
            '王牌学院':'ACE Academy','学技能 · 拿证书 · 赚代币':'Learn · Certify · Earn',
            '区块链+AI教育平台':'Blockchain + AI Education',
            '开始学习':'Start Learning','浏览课程':'Browse Courses','立即注册':'Register Now',
            '课程方向':'Directions','平台特性':'Features','准备好开始了吗？':'Ready to start?',
            '通过推荐链接注册，连接钱包，选课学习':'Register via referral, connect wallet, start learning',
            '注册':'Register','登录':'Login',
            '第一步：输入推荐人地址':'Step 1: Referral Address',
            '第1步：输入推荐人地址':'Step 1: Referral Address',
            '第2步：安全验证':'Step 2: Security Verification',
            '第3步：连接钱包授权':'Step 3: Connect Wallet',
            '第4步：注册完成':'Step 4: Complete',
            '第1步：安全验证':'Step 1: Security',
            '第2步：连接钱包':'Step 2: Connect Wallet',
            '第3步：签名授权':'Step 3: Sign to Login',
            '推荐人钱包地址':'Referral Wallet Address','推荐人':'Referrer',
            '必须通过推荐人邀请注册':'Registration requires a referral',
            '如果有推荐链接，打开链接会自动填入':'Auto-filled if you have a referral link',
            '向右滑动完成验证':'Slide right to verify',
            '验证通过':'Verified','下一步':'Next','提交':'Submit','取消':'Cancel',
            '连接钱包并授权':'Connect Wallet','连接钱包':'Connect Wallet',
            '选择钱包':'Select Wallet','你选什么钱包':'Select your wallet',
            '小狐狸钱包':'MetaMask','扫码连接':'Scan to connect',
            '请在钱包中确认连接请求':'Please confirm in your wallet',
            '需要输入密码或指纹确认':'Enter password or fingerprint',
            '我已在钱包中确认':'I confirmed in wallet',
            '授权签名':'Sign Authorization',
            '请在钱包中确认签名授权':'Please sign in your wallet',
            '此操作不消耗Gas费':'No gas fee required',
            '我已签名':'I signed','正在连接钱包':'Connecting wallet',
            '等待钱包确认':'Waiting for wallet confirmation',
            '正在验证签名':'Verifying signature','签名验证成功':'Signature verified',
            '授权成功':'Authorized','推荐关系已绑定，注册完成':'Referral bound, registration complete',
            '身份验证通过':'Identity verified','正在签名':'Signing',
            '注册成功':'Registration Success',
            '钱包地址':'Wallet Address','用户ID':'User ID',
            '已绑定':'Bound','进入学习中心':'Enter Platform',
            '签名授权登录':'Sign to Login','登录成功':'Login Success',
            '欢迎回到王牌学院':'Welcome back to ACE Academy',
            '进入学习':'Enter','钱包已连接，请完成签名授权登录':'Wallet connected, please sign to login',
            'ACE当前价格':'ACE Price','买入 ACE':'Buy ACE','卖出 ACE':'Sell ACE',
            '支付金额':'Pay Amount','卖出数量':'Sell Amount',
            '预计获得':'Expected','手续费':'Fee','销毁':'Burn','公益':'Charity',
            '实际到账':'Received','底池':'Pool','已销毁':'Burned',
            '当前总量':'Supply','最近交易':'Recent Trades','买入':'Buy','卖出':'Sell',
            '我的推荐链接':'My Referral Link','复制':'Copy',
            '收入概览':'Income Overview','直推USDT':'Direct USDT','团队代币':'Team ACE',
            '代币释放':'Released','团队数据':'Team Data','直推人数':'Direct Count',
            '团队总人数':'Team Total','团队业绩':'Team Revenue','个人业绩':'Personal Revenue',
            '当前级别':'Current Level','下一级':'Next Level','直推明细':'Direct Details',
            '升级合伙人':'Upgrade to Partner','返回':'Back','刷新':'Refresh',
            '账户信息':'Account Info','我的资产':'My Assets','可用ACE':'Available ACE',
            '锁定ACE':'Locked ACE','代币释放进度':'Release Progress',
            '已释放':'Released','未解锁':'Locked','我的证书':'My Certificates',
            '质押生息':'Staking','质押数量':'Stake Amount','质押期':'Period',
            '年化收益':'APR','预期收益':'Expected Reward','到期时间':'Maturity',
            '新增质押':'New Stake','持有权益':'Benefits','退课':'Refund',
            '申请退课':'Apply Refund','身份':'Role','学员':'Student',
            '大使':'Ambassador','合伙人':'Partner',
            '管理后台':'Admin Panel','全网统计':'Global Stats',
            '总用户数':'Total Users','总学费收入':'Total Revenue',
            '资金钱包':'Fund Wallets','平台运营USDT':'Platform USDT',
            '护盘基金':'Protection Fund','公益基金':'Charity Fund',
            '做市管理':'Market Management','推广统计':'Promotion Stats',
            '推广者人数':'Promoters','合约地址':'Contract Addresses',
            '权限状态':'Permission Status','已丢弃':'Renounced','未丢弃':'Active',
            '管理操作':'Admin Actions','补充护盘基金':'Top Up Protection',
            '提取超出部分':'Withdraw Excess','月度回购销毁':'Monthly Buyback',
            '紧急暂停':'Emergency Pause','返回首页':'Back to Home',
            '学习进度':'Learning Progress','总学习时长':'Total Hours',
            '已学时长':'Learned Hours','已释放代币':'Released Tokens',
            '课程列表':'Course List','完成本课':'Complete','复习':'Review',
            '进行中':'In Progress','参加考试':'Take Exam',
            '综合考试':'Comprehensive Exam','考试方向':'Direction',
            '题目数量':'Questions','题型':'Type','及格分数':'Passing Score',
            '考试时长':'Duration','考试次数':'Attempts','不限':'Unlimited',
            '开始考试':'Start Exam','考试通过！':'Exam Passed!','未通过':'Failed',
            '答对':'Correct','重新考试':'Retry','铸造链上证书':'Mint Certificate',
            '课程库':'Course Library','小时内容':'hrs content',
            '课程成本':'Course Cost','入门':'Beginner','进阶':'Intermediate',
            '高级':'Advanced','观看视频':'Watch Video','实操练习':'Practice',
            '写代码':'Code','考试测评':'Exam','零基础':'Zero Base',
            '有基础':'Some Base','比较熟悉':'Proficient',
            '方向':'Direction','门课程':'courses','ACE总量':'ACE Total',
            '方案生成完毕':'Plan generated','你的专属学习方案':'Your Personalized Plan',
            '方案已确认':'Plan confirmed','付费后即可开始学习':'Pay to start learning',
            '重新规划':'Replan','确认方案':'Confirm Plan',
            '碎片时间学习':'Spare time','每天固定时间':'Fixed time daily',
            '投入较多时间':'More time','找工作':'Find a job','创业':'Start business',
            '提升技能':'Improve skills','兴趣':'Interest',
            '学技能':'Learn','拿证书':'Certify','赚代币':'Earn',

            '第1步：输入推荐人地址':'Step 1: Referral Address',
            '第1步：输入':'Step 1: Enter',
            '地址':'Address',
            '邀请注册':'to register',
            '必须通过':'Requires referral',
            '输入推荐人地址 0x...':'Enter referral address 0x...',
            '在这里输入你想学的具体内容...（可跳过）':'Type what you want to learn... (optional)',
            '钱包地址即账户 · 无需邮箱密码':'Wallet address = account, no email/password needed',
            '连接钱包即同意':'Connect wallet to agree to',
            '用户协议':'Terms',
            '和':'and',
            '隐私政策':'Privacy Policy',
            '推荐人钱包地址':'Referral Wallet Address',
            '推荐人信息':'Referrer Info',
            '推荐关系':'Referral Relationship',
            '修改':'Edit',
            '我的推荐链接':'My Referral Link',
            '分享给朋友，他们注册学习你就能赚取奖励':'Share with friends, earn when they learn',
            '今日':'Today','累计':'Total','本月':'This Month',
            '距升级还差':'To upgrade: need',
            '人':'people','业绩':'revenue',
            '升级为合伙人':'Upgrade to Partner',
            '合伙人享有区域运营权':'Partners get regional operation rights',
            '拿平台运营费80%分成':'80% of platform fees',
            '门槛：2万U':'Fee: 20,000U',
            '永久上限50人':'Max 50 partners permanently',
            '已上链':'On-chain','永久有效':'Permanently valid',
            '退课后课程作废':'Courses void after refund',
            '剩余代币全部一次性释放':'All remaining tokens released',
            '不退USDT':'No USDT refund',
            '不影响推荐人':'Does not affect referrer',
            '新增质押':'New Stake','持有':'Holding','解锁':'Unlock',
            '课程':'Course','方向':'Direction',
            '门课程':'courses','ACE总量':'ACE Total',
            '方案生成完毕':'Plan generated',
            '你的专属学习方案':'Your Personalized Plan',
            '方案已确认':'Plan confirmed',
            '付费后即可开始学习':'Pay to start learning',
            '重新规划':'Replan','确认方案':'Confirm Plan',
            '进入学习':'Enter',
            '管理后台只读取链上数据':'Admin panel only reads on-chain data',
            '当前连接':'Connected as',
            '管理员':'Admin',
            '数据已刷新':'Data refreshed',
        },
        ja: {
            '王牌学院':'ACE Academy','学技能 · 拿证书 · 赚代币':'スキル · 証明 · 獲得',
            '区块链+AI教育平台':'ブロックチェーン+AI教育',
            '注册':'登録','登录':'ログイン','开始学习':'学習開始','浏览课程':'コース一覧',
            '下一步':'次へ','提交':'送信','取消':'キャンセル','复制':'コピー',
            '返回':'戻る','刷新':'更新',
        },
        ko: {
            '王牌学院':'ACE Academy','学技能 · 拿证书 · 赚代币':'스킬 · 자격 · 획득',
            '区块链+AI教育平台':'블록체인+AI 교육',
            '注册':'가입','登录':'로그인','开始学习':'학습시작','浏览课程':'강의보기',
            '下一步':'다음','提交':'제출','取消':'취소','复制':'복사',
            '返回':'뒤로','刷新':'새로고침',
        },
        es: {
            '王牌学院':'ACE Academy','学技能 · 拿证书 · 赚代币':'Aprende · Certifica · Gana',
            '区块链+AI教育平台':'Blockchain + IA Educación',
            '注册':'Registro','登录':'Acceso','开始学习':'Empezar','浏览课程':'Ver Cursos',
            '下一步':'Siguiente','提交':'Enviar','取消':'Cancelar','复制':'Copiar',
            '返回':'Volver','刷新':'Actualizar',
        }
    };
    
    const dict = T[lang];
    if (!dict) return;
    
    // 遍历所有文本节点并翻译
    function walk(node) {
        if (node.nodeType === 3) { // 文本节点
            let text = node.textContent.trim();
            if (text && dict[text]) {
                node.textContent = dict[text];
            }
        } else if (node.nodeType === 1) { // 元素节点
            // 跳过script和style
            if (node.tagName === 'SCRIPT' || node.tagName === 'STYLE') return;
            for (let child of node.childNodes) {
                walk(child);
            }
        }
    }
    
    walk(document.body);
}

// 页面加载后执行
window.addEventListener('DOMContentLoaded', function() {
    setTimeout(translatePage, 100);
});

// 语言切换后也执行
window.addEventListener('load', function() {
    setTimeout(translatePage, 200);
});
