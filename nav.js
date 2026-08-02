// 阿奇学院统一导航栏 + 完整多语言系统
// 支持语言：中文(zh) 英文(en) 日文(ja) 韩文(ko) 西班牙文(es)

const LANGS = [
    {code:'zh', name:'中文', flag:'🇨🇳'},
    {code:'en', name:'EN', flag:'🇺🇸'},
    {code:'ja', name:'日本語', flag:'🇯🇵'},
    {code:'ko', name:'한국어', flag:'🇰🇷'},
    {code:'es', name:'Español', flag:'🇪🇸'},
];

function getCurrentLang() {
    return localStorage.getItem('ace_lang') || 'zh';
}

function createNav(active) {
    const lang = getCurrentLang();
    const nav = document.createElement('div');
    nav.className = 'ace-nav';
    
    // 语言下拉
    let langOptions = '';
    LANGS.forEach(l => {
        langOptions += `<button onclick="switchLang('${l.code}')" class="lang-option ${lang===l.code?'active':''}">${l.flag} ${l.name}</button>`;
    });
    
    nav.innerHTML = `
    <div class="nav-bar">
        <div class="nav-inner">
            <a href="index.html" class="nav-logo">
                <div class="nav-logo-icon"><img src="images/ace-logo.png" style="width:24px;height:24px;border-radius:5px" alt="ACE"></div>
                <span class="nav-logo-text">ACE</span>
            </a>
            <div class="nav-lang-wrap">
                <button class="lang-current" onclick="toggleLangMenu()">${LANGS.find(l=>l.code===lang)?.flag||'🇨🇳'} ${LANGS.find(l=>l.code===lang)?.name||'中文'} <i class="ph ph-caret-down"></i></button>
                <div class="lang-menu" id="langMenu" style="display:none">
                    ${langOptions}
                </div>
            </div>
        </div>
        <div class="nav-tabs">
            <a href="index.html" class="nav-tab ${active==='home'?'on':''}"><i class="ph-fill ph-house"></i><span data-i18n="nav_home"></span></a>
            <a href="course-library.html" class="nav-tab ${active==='course'?'on':''}"><i class="ph ph-books"></i><span data-i18n="nav_courses"></span></a>
            <a href="learning.html" class="nav-tab ${active==='learn'?'on':''}"><i class="ph-fill ph-graduation-cap"></i><span data-i18n="nav_learning"></span></a>
            <a href="trade.html" class="nav-tab ${active==='trade'?'on':''}"><i class="ph-fill ph-currency-btc"></i><span data-i18n="nav_trade"></span></a>
            <a href="promote.html" class="nav-tab ${active==='promote'?'on':''}"><i class="ph-fill ph-megaphone"></i><span data-i18n="nav_promote"></span></a>
            <a href="profile.html" class="nav-tab ${active==='profile'?'on':''}"><i class="ph-fill ph-user"></i><span data-i18n="nav_me"></span></a>
            <a href="login.html" class="nav-tab ${active==='login'?'on':''}"><i class="ph ph-sign-in"></i><span data-i18n="nav_login"></span></a>
        </div>
    </div>`;
    document.body.insertBefore(nav, document.body.firstChild);
    
    // 点击外部关闭语言菜单
    document.addEventListener('click', function(e) {
        if (!e.target.closest('.nav-lang-wrap')) {
            const menu = document.getElementById('langMenu');
            if (menu) menu.style.display = 'none';
        }
    });
    
    applyLang();
}

function toggleLangMenu() {
    const menu = document.getElementById('langMenu');
    if (menu) menu.style.display = menu.style.display === 'none' ? 'block' : 'none';
}

function switchLang(l) {
    localStorage.setItem('ace_lang', l);
    location.reload();
}

// ========== 完整翻译字典 ==========
const I18N = {
    // 导航栏
    nav_home: {zh:'首页', en:'Home', ja:'ホーム', ko:'홈', es:'Inicio'},
    nav_courses: {zh:'课程', en:'Courses', ja:'コース', ko:'강의', es:'Cursos'},
    nav_learning: {zh:'学习', en:'Learn', ja:'学習', ko:'학습', es:'Aprender'},
    nav_trade: {zh:'交易', en:'Trade', ja:'取引', ko:'거래', es:'Comercio'},
    nav_promote: {zh:'推广', en:'Promote', ja:'推广', ko:'홍보', es:'Promover'},
    nav_me: {zh:'我的', en:'Profile', ja:'マイ', ko:'내정보', es:'Perfil'},
    nav_login: {zh:'登录', en:'Login', ja:'ログイン', ko:'로그인', es:'Acceder'},
    
    // 首页
    hero_title: {zh:'学技能 · 拿证书 · 赚代币', en:'Learn Skills · Earn Certificates · Earn Tokens', ja:'スキル習得 · 証明書取得 · トークン獲得', ko:'스킬습득 · 자격증취득 · 토큰획득', es:'Aprende · Certifícate · Gana Tokens'},
    hero_sub: {zh:'区块链+AI教育平台', en:'Blockchain + AI Education Platform', ja:'ブロックチェーン+AI教育プラットフォーム', ko:'블록체인+AI 교육 플랫폼', es:'Plataforma de Educación Blockchain + IA'},
    start_learning: {zh:'开始学习', en:'Start Learning', ja:'学習開始', ko:'학습시작', es:'Empezar'},
    browse_courses: {zh:'浏览课程', en:'Browse Courses', ja:'コース一覧', ko:'강의보기', es:'Ver Cursos'},
    dir_title: {zh:'课程方向', en:'Course Directions', ja:'コース方向', ko:'강의분야', es:'Direcciones'},
    feat_title: {zh:'平台特性', en:'Platform Features', ja:'プラットフォーム特徴', ko:'플랫폼특징', es:'Características'},
    cta_title: {zh:'准备好开始了吗？', en:'Ready to start?', ja:'始める準備はできましたか？', ko:'시작할 준비가 되셨나요?', es:'¿Listo para empezar?'},
    cta_sub: {zh:'通过推荐链接注册，连接钱包，选课学习', en:'Register via referral, connect wallet, start learning', ja:'紹介リンクで登録、ウォレット接続、学習開始', ko:'추천링크로 가입, 지갑연결, 학습시작', es:'Regístrate, conecta tu wallet, aprende'},
    register_now: {zh:'立即注册', en:'Register Now', ja:'今すぐ登録', ko:'지금 가입', es:'Registrarse'},
    
    // 首页统计
    stat_directions: {zh:'课程方向', en:'Directions', ja:'方向', ko:'분야', es:'Direcciones'},
    stat_courses: {zh:'门课程', en:'Courses', ja:'コース', ko:'강의', es:'Cursos'},
    stat_total: {zh:'ACE总量', en:'ACE Total', ja:'ACE総量', ko:'ACE총량', es:'ACE Total'},
    
    // 首页方向
    dir_ai: {zh:'AI应用', en:'AI Application', ja:'AI応用', ko:'AI응용', es:'IA Aplicada'},
    dir_ai_desc: {zh:'ChatGPT · AI绘画 · AI视频', en:'ChatGPT · AI Art · AI Video', ja:'ChatGPT · AI画像 · AI動画', ko:'ChatGPT · AI그림 · AI영상', es:'ChatGPT · Arte IA · Video IA'},
    dir_block: {zh:'区块链/Web3', en:'Blockchain/Web3', ja:'ブロックチェーン', ko:'블록체인', es:'Blockchain'},
    dir_block_desc: {zh:'钱包 · DeFi · 智能合约', en:'Wallet · DeFi · Smart Contracts', ja:'ウォレット · DeFi · スマートコントラクト', ko:'지갑 · DeFi · 스마트컨트랙트', es:'Wallet · DeFi · Contratos'},
    dir_ecom: {zh:'跨境电商', en:'Cross-border E-commerce', ja:'越境EC', ko:'크로스보더 전자상거래', es:'E-commerce Internacional'},
    dir_ecom_desc: {zh:'亚马逊 · Shopee · TikTok', en:'Amazon · Shopee · TikTok', ja:'Amazon · Shopee · TikTok', ko:'Amazon · Shopee · TikTok', es:'Amazon · Shopee · TikTok'},
    dir_mkt: {zh:'数字营销', en:'Digital Marketing', ja:'デジタルマーケティング', ko:'디지털마케팅', es:'Marketing Digital'},
    dir_mkt_desc: {zh:'社媒 · 内容 · 私域', en:'Social · Content · Private', ja:'SNS · コンテンツ · プライベート', ko:'소셜 · 콘텐츠 · 프라이빗', es:'Social · Contenido · Privado'},
    dir_code: {zh:'编程入门', en:'Programming', ja:'プログラミング入門', ko:'프로그래밍입문', es:'Programación'},
    dir_code_desc: {zh:'Python · 网页 · AI编程', en:'Python · Web · AI Coding', ja:'Python · Web · AIコーディング', ko:'Python · 웹 · AI코딩', es:'Python · Web · IA'},
    
    // 首页特性
    feat_ai_title: {zh:'AI定制学习方案', en:'AI Custom Learning Plan', ja:'AIカスタム学習プラン', ko:'AI맞춤 학습계획', es:'Plan de Aprendizaje IA'},
    feat_ai_desc: {zh:'5个问题了解你的需求，AI生成专属学习路径，不再千篇一律', en:'5 questions, AI generates your personalized learning path', ja:'5つの質問でAIが専用学習パスを生成', ko:'5개 질문으로 AI가 맞춤 학습경로 생성', es:'5 preguntas, IA crea tu ruta personalizada'},
    feat_cert_title: {zh:'链上证书不可篡改', en:'On-chain Certificates', ja:'ブロックチェーン証明書', ko:'온체인 자격증', es:'Certificados en Cadena'},
    feat_cert_desc: {zh:'学完考试通过，铸造NFT证书，永久记录在区块链上，全球可查', en:'Mint NFT certificate, permanently on-chain, globally verifiable', ja:'NFT証明書発行、永続的にブロックチェーンに記録', ko:'NFT 자격증 발행, 영구 기록, 전 세계 조회 가능', es:'Mint NFT, permanente, verificable globalmente'},
    feat_token_title: {zh:'学习即赚代币', en:'Learn to Earn', ja:'学習でトークン獲得', ko:'학습하며 토큰 획득', es:'Aprende y Gana'},
    feat_token_desc: {zh:'买课程送等值ACE代币，学完释放，代币随平台成长升值', en:'Buy courses, get ACE tokens, release as you learn', ja:'コース購入でACEトークン付与、学習で解放', ko:'강의 구매시 ACE 토큰 지급, 학습으로 해제', es:'Compra cursos, gana ACE, libera al aprender'},
    feat_promo_title: {zh:'推广赚现金', en:'Promote to Earn', ja:'紹介で現金獲得', ko:'홍보로 현금 획득', es:'Promociona y Gana'},
    feat_promo_desc: {zh:'推荐朋友学习，直推拿USDT现金，团队分红拿ACE代币', en:'Refer friends, earn USDT cash, team dividends in ACE', ja:'友人紹介でUSDT獲得、チーム配当はACE', ko:'친구 추천으로 USDT 획득, 팀 배당은 ACE', es:'Refiere, gana USDT, dividendos en ACE'},
    feat_safe_title: {zh:'资金透明安全', en:'Transparent & Safe', ja:'透明・安全な資金', ko:'투명하고 안전한 자금', es:'Transparente y Seguro'},
    feat_safe_desc: {zh:'智能合约自动执行，链上可查，底池LP永久销毁，不可撤池', en:'Smart contracts, on-chain, LP burned permanently', ja:'スマートコントラクト、オンチェーン、LP永久焼却', ko:'스마트컨트랙트, 온체인, LP 영구 소각', es:'Contratos, on-chain, LP quemado'},
    feat_charity_title: {zh:'公益基金', en:'Charity Fund', ja:'公益基金', ko:'공익기금', es:'Fondo Caritativo'},
    feat_charity_desc: {zh:'每笔收入1%进入公益基金，资助贫困学员，捐赠教育机构', en:'1% of revenue to charity, help students, donate to schools', ja:'収入の1%が公益基金、学生支援、教育機関寄付', ko:'수익의 1% 공익기금, 학생 지원, 교육기관 기부', es:'1% a caridad, ayuda estudiantes, dona escuelas'},
    
    // 页脚
    footer_tagline: {zh:'学技能 · 拿证书 · 赚代币', en:'Learn · Certify · Earn', ja:'スキル · 証明 · 獲得', ko:'스킬 · 자격 · 획득', es:'Aprende · Certifica · Gana'},
    
    // 通用
    back: {zh:'返回', en:'Back', ja:'戻る', ko:'뒤로', es:'Volver'},
    refresh: {zh:'刷新', en:'Refresh', ja:'更新', ko:'새로고침', es:'Actualizar'},
    confirm: {zh:'确认', en:'Confirm', ja:'確認', ko:'확인', es:'Confirmar'},
    cancel: {zh:'取消', en:'Cancel', ja:'キャンセル', ko:'취소', es:'Cancelar'},
    submit: {zh:'提交', en:'Submit', ja:'送信', ko:'제출', es:'Enviar'},
    next: {zh:'下一步', en:'Next', ja:'次へ', ko:'다음', es:'Siguiente'},
    
    // 登录注册
    tab_register: {zh:'注册', en:'Register', ja:'登録', ko:'가입', es:'Registro'},
    tab_login: {zh:'登录', en:'Login', ja:'ログイン', ko:'로그인', es:'Acceso'},
    step1_ref: {zh:'第1步：输入推荐人地址', en:'Step 1: Referral Address', ja:'ステップ1：紹介者アドレス', ko:'1단계: 추천인 주소', es:'Paso 1: Dirección de Referencia'},
    step2_verify: {zh:'第2步：安全验证', en:'Step 2: Security Verification', ja:'ステップ2：セキュリティ認証', ko:'2단계: 보안인증', es:'Paso 2: Verificación'},
    step3_wallet: {zh:'第3步：连接钱包授权', en:'Step 3: Connect Wallet', ja:'ステップ3：ウォレット接続', ko:'3단계: 지갑연결', es:'Paso 3: Conectar Wallet'},
    step4_done: {zh:'第4步：注册完成', en:'Step 4: Complete', ja:'ステップ4：登録完了', ko:'4단계: 가입완료', es:'Paso 4: Completado'},
    ref_placeholder: {zh:'输入推荐人地址 0x...', en:'Enter referral address 0x...', ja:'紹介者アドレス 0x...', ko:'추천인 주소 0x...', es:'Dirección de referral 0x...'},
    ref_required: {zh:'必须通过推荐人邀请注册', en:'Registration requires referral', ja:'紹介者経由の登録が必要', ko:'추천인을 통한 가입 필요', es:'Registro requiere referencia'},
    slide_verify: {zh:'向右滑动完成验证', en:'Slide right to verify', ja:'右にスライドして認証', ko:'오른쪽으로 슬라이드하여 인증', es:'Desliza para verificar'},
    verify_passed: {zh:'验证通过', en:'Verified', ja:'認証完了', ko:'인증완료', es:'Verificado'},
    connect_wallet: {zh:'连接钱包并授权', en:'Connect Wallet', ja:'ウォレット接続', ko:'지갑연결', es:'Conectar Wallet'},
    reg_success: {zh:'注册成功', en:'Registration Success', ja:'登録成功', ko:'가입성공', es:'Registro Exitoso'},
    enter_platform: {zh:'进入学习中心', en:'Enter Platform', ja:'プラットフォームへ', ko:'플랫폼 입장', es:'Entrar'},
    wallet_addr: {zh:'钱包地址', en:'Wallet Address', ja:'ウォレットアドレス', ko:'지갑주소', es:'Dirección Wallet'},
    user_id: {zh:'用户ID', en:'User ID', ja:'ユーザーID', ko:'사용자ID', es:'ID de Usuario'},
    referrer: {zh:'推荐人', en:'Referrer', ja:'紹介者', ko:'추천인', es:'Referente'},
    ref_bound: {zh:'已绑定', en:'Bound', ja:'バインド済み', ko:'연결됨', es:'Vinculado'},
    sign_auth: {zh:'签名授权登录', en:'Sign to Login', ja:'署名してログイン', ko:'서명하여 로그인', es:'Firmar para Acceder'},
    login_success: {zh:'登录成功', en:'Login Success', ja:'ログイン成功', ko:'로그인성공', es:'Acceso Exitoso'},
    welcome_back: {zh:'欢迎回到阿奇学院', en:'Welcome back to ACE Academy', ja:'ACE Academyへお帰りなさい', ko:'ACE Academy에 오신 것을 환영합니다', es:'Bienvenido de vuelta'},
    
    // 交易
    ace_price: {zh:'ACE 当前价格', en:'ACE Current Price', ja:'ACE現在価格', ko:'ACE 현재 가격', es:'Precio ACE'},
    buy_ace: {zh:'买入 ACE', en:'Buy ACE', ja:'ACE購入', ko:'ACE 구매', es:'Comprar ACE'},
    sell_ace: {zh:'卖出 ACE', en:'Sell ACE', ja:'ACE売却', ko:'ACE 판매', es:'Vender ACE'},
    pay_amount: {zh:'支付金额', en:'Pay Amount', ja:'支払金額', ko:'지불금액', es:'Cantidad a Pagar'},
    sell_amount: {zh:'卖出数量', en:'Sell Amount', ja:'売却数量', ko:'판매수량', es:'Cantidad a Vender'},
    expected: {zh:'预计获得', en:'Expected', ja:'期待獲得', ko:'예상획득', es:'Esperado'},
    fee: {zh:'手续费', en:'Fee', ja:'手数料', ko:'수수료', es:'Comisión'},
    burn: {zh:'销毁', en:'Burn', ja:'焼却', ko:'소각', es:'Quemar'},
    charity: {zh:'公益', en:'Charity', ja:'公益', ko:'공익', es:'Caridad'},
    actual_received: {zh:'实际到账', en:'Actual Received', ja:'実際の受取', ko:'실제수령', es:'Recibido'},
    pool: {zh:'底池', en:'Pool', ja:'プール', ko:'풀', es:'Pool'},
    burned: {zh:'已销毁', en:'Burned', ja:'焼却済み', ko:'소각됨', es:'Quemado'},
    current_supply: {zh:'当前总量', en:'Current Supply', ja:'現在総量', ko:'현재총량', es:'Suministro'},
    recent_trades: {zh:'最近交易', en:'Recent Trades', ja:'最近の取引', ko:'최근거래', es:'Operaciones Recientes'},
    
    // 推广
    my_ref_link: {zh:'我的推荐链接', en:'My Referral Link', ja:'紹介リンク', ko:'내 추천링크', es:'Mi Enlace'},
    copy: {zh:'复制', en:'Copy', ja:'コピー', ko:'복사', es:'Copiar'},
    income_overview: {zh:'收入概览', en:'Income Overview', ja:'収入概要', ko:'수입개요', es:'Resumen de Ingresos'},
    direct_usdt: {zh:'直推USDT', en:'Direct USDT', ja:'直接紹介USDT', ko:'직추천 USDT', es:'USDT Directo'},
    team_ace: {zh:'团队代币', en:'Team ACE', ja:'チームACE', ko:'팀 ACE', es:'ACE de Equipo'},
    token_released: {zh:'代币释放', en:'Token Released', ja:'トークン解放', ko:'토큰해제', es:'Tokens Liberados'},
    team_data: {zh:'团队数据', en:'Team Data', ja:'チームデータ', ko:'팀데이터', es:'Datos de Equipo'},
    direct_count: {zh:'直推人数', en:'Direct Count', ja:'直接紹介数', ko:'직추천수', es:'Directos'},
    team_total: {zh:'团队总人数', en:'Team Total', ja:'チーム総数', ko:'팀총원', es:'Total Equipo'},
    team_revenue: {zh:'团队业绩', en:'Team Revenue', ja:'チーム業績', ko:'팀실적', es:'Ingresos Equipo'},
    personal_revenue: {zh:'个人业绩', en:'Personal Revenue', ja:'個人業績', ko:'개인실적', es:'Ingresos Personales'},
    current_level: {zh:'当前级别', en:'Current Level', ja:'現在レベル', ko:'현재등급', es:'Nivel Actual'},
    next_level: {zh:'下一级', en:'Next Level', ja:'次のレベル', ko:'다음등급', es:'Siguiente Nivel'},
    direct_detail: {zh:'直推明细', en:'Direct Details', ja:'直接紹介詳細', ko:'직추천 상세', es:'Detalles Directos'},
    upgrade_partner: {zh:'升级合伙人', en:'Upgrade to Partner', ja:'パートナーへ昇格', ko:'파트너로 승격', es:'Ser Socio'},
    
    // 个人中心
    account_info: {zh:'账户信息', en:'Account Info', ja:'アカウント情報', ko:'계정정보', es:'Información de Cuenta'},
    my_assets: {zh:'我的资产', en:'My Assets', ja:'マイアセット', ko:'내자산', es:'Mis Activos'},
    available_ace: {zh:'可用ACE', en:'Available ACE', ja:'利用可能ACE', ko:'사용가능 ACE', es:'ACE Disponible'},
    locked_ace: {zh:'锁定ACE', en:'Locked ACE', ja:'ロックACE', ko:'잠금 ACE', es:'ACE Bloqueado'},
    release_progress: {zh:'代币释放进度', en:'Release Progress', ja:'解放進捗', ko:'해제진행률', es:'Progreso de Liberación'},
    released: {zh:'已释放', en:'Released', ja:'解放済み', ko:'해제됨', es:'Liberado'},
    locked: {zh:'未解锁', en:'Locked', ja:'未解放', ko:'미해제', es:'Bloqueado'},
    my_cert: {zh:'我的证书', en:'My Certificates', ja:'マイ証明書', ko:'내자격증', es:'Mis Certificados'},
    staking: {zh:'质押生息', en:'Staking', ja:'ステーキング', ko:'스테이킹', es:'Staking'},
    stake_amount: {zh:'质押数量', en:'Stake Amount', ja:'ステーク量', ko:'스테이크량', es:'Cantidad'},
    stake_period: {zh:'质押期', en:'Period', ja:'期間', ko:'기간', es:'Período'},
    apr: {zh:'年化收益', en:'APR', ja:'年利', ko:'연수익률', es:'Rendimiento Anual'},
    expected_reward: {zh:'预期收益', en:'Expected Reward', ja:'期待報酬', ko:'예상보상', es:'Recompensa Esperada'},
    maturity: {zh:'到期时间', en:'Maturity', ja:'満期', ko:'만기', es:'Vencimiento'},
    new_stake: {zh:'新增质押', en:'New Stake', ja:'新規ステーク', ko:'신규스테이크', es:'Nueva Inversión'},
    holding_benefits: {zh:'持有权益', en:'Holding Benefits', ja:'保有特典', ko:'보유혜택', es:'Beneficios'},
    refund_course: {zh:'退课', en:'Refund Course', ja:'コース返金', ko:'강의환불', es:'Reembolso'},
    apply_refund: {zh:'申请退课', en:'Apply Refund', ja:'返金申請', ko:'환불신청', es:'Solicitar Reembolso'},
    
    // 管理后台
    admin_panel: {zh:'管理后台', en:'Admin Panel', ja:'管理パネル', ko:'관리패널', es:'Panel Admin'},
    global_stats: {zh:'全网统计', en:'Global Stats', ja:'全体統計', ko:'전체통계', es:'Estadísticas Globales'},
    total_users: {zh:'总用户数', en:'Total Users', ja:'総ユーザー数', ko:'총사용자', es:'Usuarios Totales'},
    total_revenue: {zh:'总学费收入', en:'Total Revenue', ja:'総収入', ko:'총수입', es:'Ingresos Totales'},
    fund_wallets: {zh:'资金钱包', en:'Fund Wallets', ja:'資金ウォレット', ko:'자금지갑', es:'Billeteras'},
    platform_fund: {zh:'平台运营USDT', en:'Platform USDT', ja:'プラットフォームUSDT', ko:'플랫폼 USDT', es:'USDT Plataforma'},
    protection_fund: {zh:'护盘基金', en:'Protection Fund', ja:'保護基金', ko:'보호기금', es:'Fondo de Protección'},
    charity_fund: {zh:'公益基金', en:'Charity Fund', ja:'公益基金', ko:'공익기금', es:'Fondo Caritativo'},
    market_mgmt: {zh:'做市管理', en:'Market Management', ja:'市場管理', ko:'시장관리', es:'Gestión de Mercado'},
    promo_stats: {zh:'推广统计', en:'Promotion Stats', ja:'推广統計', ko:'홍보통계', es:'Estadísticas de Promoción'},
    promoter_count: {zh:'推广者人数', en:'Promoters', ja:'推進者数', ko:'홍보자수', es:'Promotores'},
    contract_addr: {zh:'合约地址', en:'Contract Addresses', ja:'コントラクトアドレス', ko:'컨트랙트주소', es:'Direcciones de Contrato'},
    permission_status: {zh:'权限状态', en:'Permission Status', ja:'権限状態', ko:'권한상태', es:'Estado de Permisos'},
    renounced: {zh:'已丢弃', en:'Renounced', ja:'破棄済み', ko:'폐기됨', es:'Renunciado'},
    not_renounced: {zh:'未丢弃', en:'Active', ja:'未破棄', ko:'미폐기', es:'Activo'},
    admin_actions: {zh:'管理操作', en:'Admin Actions', ja:'管理操作', ko:'관리작업', es:'Acciones'},
    topup_protection: {zh:'补充护盘基金', en:'Top Up Protection', ja:'保護基金補充', ko:'보호기금충전', es:'Recargar Protección'},
    withdraw_excess: {zh:'提取超出部分', en:'Withdraw Excess', ja:'超過分引き出し', ko:'초과분인출', es:'Retirar Exceso'},
    monthly_buyback: {zh:'月度回购销毁', en:'Monthly Buyback', ja:'月次買い戻し', ko:'월간매수', es:'Recompra Mensual'},
    emergency_pause: {zh:'紧急暂停', en:'Emergency Pause', ja:'緊急停止', ko:'긴급정지', es:'Pausa de Emergencia'},
    
    // 学习
    learning_progress: {zh:'学习进度', en:'Learning Progress', ja:'学習進捗', ko:'학습진행률', es:'Progreso de Aprendizaje'},
    courses_completed: {zh:'已完成', en:'Completed', ja:'完了', ko:'완료', es:'Completado'},
    total_courses: {zh:'门课程', en:'courses', ja:'コース', ko:'강의', es:'cursos'},
    total_hours: {zh:'总学习时长', en:'Total Hours', ja:'総学習時間', ko:'총학습시간', es:'Horas Totales'},
    learned_hours: {zh:'已学时长', en:'Learned Hours', ja:'学習済み時間', ko:'학습시간', es:'Horas Aprendidas'},
    token_released_2: {zh:'已释放代币', en:'Tokens Released', ja:'解放トークン', ko:'해제토큰', es:'Tokens Liberados'},
    course_list: {zh:'课程列表', en:'Course List', ja:'コースリスト', ko:'강의목록', es:'Lista de Cursos'},
    start_learn: {zh:'开始学习', en:'Start Learning', ja:'学習開始', ko:'학습시작', es:'Empezar'},
    complete_course: {zh:'完成本课', en:'Complete', ja:'完了', ko:'완료', es:'Completar'},
    review: {zh:'复习', en:'Review', ja:'復習', ko:'복습', es:'Revisar'},
    in_progress: {zh:'进行中', en:'In Progress', ja:'進行中', ko:'진행중', es:'En Progreso'},
    not_unlocked: {zh:'未解锁', en:'Locked', ja:'未解放', ko:'미해제', es:'Bloqueado'},
    take_exam: {zh:'参加考试', en:'Take Exam', ja:'試験受験', ko:'시험응시', es:'Examen'},
    
    // 考试
    comprehensive_exam: {zh:'综合考试', en:'Comprehensive Exam', ja:'総合試験', ko:'종합시험', es:'Examen Completo'},
    exam_direction: {zh:'考试方向', en:'Direction', ja:'方向', ko:'방향', es:'Dirección'},
    question_count: {zh:'题目数量', en:'Questions', ja:'問題数', ko:'문제수', es:'Preguntas'},
    question_type: {zh:'题型', en:'Type', ja:'問題形式', ko:'문제유형', es:'Tipo'},
    passing_score: {zh:'及格分数', en:'Passing Score', ja:'合格点', ko:'합격점수', es:'Nota de Aprobación'},
    exam_duration: {zh:'考试时长', en:'Duration', ja:'試験時間', ko:'시험시간', es:'Duración'},
    attempts: {zh:'考试次数', en:'Attempts', ja:'受験回数', ko:'응시횟수', es:'Intentos'},
    unlimited: {zh:'不限', en:'Unlimited', ja:'無制限', ko:'무제한', es:'Ilimitado'},
    start_exam: {zh:'开始考试', en:'Start Exam', ja:'試験開始', ko:'시험시작', es:'Empezar Examen'},
    exam_passed: {zh:'考试通过！', en:'Exam Passed!', ja:'試験合格！', ko:'시험합격！', es:'¡Aprobado!'},
    exam_failed: {zh:'未通过', en:'Failed', ja:'不合格', ko:'불합격', es:'Reprobado'},
    correct_answers: {zh:'答对', en:'Correct', ja:'正解', ko:'정답', es:'Correctas'},
    retry_exam: {zh:'重新考试', en:'Retry', ja:'再受験', ko:'재응시', es:'Reintentar'},
    mint_certificate: {zh:'铸造链上证书', en:'Mint Certificate', ja:'証明書発行', ko:'자격증발행', es:'Acuñar Certificado'},
    
    // 课程库
    course_library: {zh:'课程库', en:'Course Library', ja:'コースライブラリ', ko:'강의실', es:'Biblioteca de Cursos'},
    hours_content: {zh:'小时内容', en:'hours content', ja:'時間コンテンツ', ko:'시간콘텐츠', es:'horas contenido'},
    course_cost: {zh:'课程成本', en:'Course Cost', ja:'コース費用', ko:'강의비용', es:'Costo'},
    beginner: {zh:'入门', en:'Beginner', ja:'入門', ko:'입문', es:'Principiante'},
    intermediate: {zh:'进阶', en:'Intermediate', ja:'中級', ko:'중급', es:'Intermedio'},
    advanced: {zh:'高级', en:'Advanced', ja:'上級', ko:'고급', es:'Avanzado'},
    watch_video: {zh:'观看视频', en:'Watch Video', ja:'動画視聴', ko:'동영상시청', es:'Ver Video'},
    practice: {zh:'实操练习', en:'Practice', ja:'実践', ko:'실습', es:'Práctica'},
    write_code: {zh:'写代码', en:'Code', ja:'コーディング', ko:'코딩', es:'Programar'},
    exam_test: {zh:'考试测评', en:'Exam', ja:'試験', ko:'시험', es:'Examen'},
    zero_basis: {zh:'零基础', en:'Zero Base', ja:'ゼロから', ko:'입문자', es:'Sin Base'},
    some_basis: {zh:'有基础', en:'Some Base', ja:'基礎あり', ko:'기초있음', es:'Con Base'},
    proficient: {zh:'比较熟悉', en:'Proficient', ja:'熟知', ko:'숙련', es:'Competente'},
};

function t(key) {
    const lang = getCurrentLang();
    const entry = I18N[key];
    if (!entry) return key;
    return entry[lang] || entry.zh || key;
}

function applyLang() {
    const lang = getCurrentLang();
    
    // 翻译所有带data-i18n的元素
    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        const entry = I18N[key];
        if (entry) {
            el.textContent = entry[lang] || entry.zh || key;
        }
    });
    
    // 翻译带data-i18n-html的元素（支持HTML）
    document.querySelectorAll('[data-i18n-html]').forEach(el => {
        const key = el.getAttribute('data-i18n-html');
        const entry = I18N[key];
        if (entry) {
            el.innerHTML = entry[lang] || entry.zh || key;
        }
    });
    
    // 翻译带data-i18n-ph的元素（placeholder）
    document.querySelectorAll('[data-i18n-ph]').forEach(el => {
        const key = el.getAttribute('data-i18n-ph');
        const entry = I18N[key];
        if (entry) {
            el.placeholder = entry[lang] || entry.zh || key;
        }
    });
    
    // 设置html lang属性
    document.documentElement.lang = lang;
}

// 导航栏CSS
const navCSS = `
.ace-nav { position:sticky; top:0; z-index:999; background:rgba(10,10,26,0.95); backdrop-filter:blur(20px); -webkit-backdrop-filter:blur(20px); border-bottom:1px solid rgba(139,137,255,0.2); }
.nav-bar { max-width:600px; margin:0 auto; }
.nav-inner { display:flex; align-items:center; justify-content:space-between; padding:8px 16px; }
.nav-logo { display:flex; align-items:center; gap:8px; text-decoration:none; }
.nav-logo-icon { width:32px; height:32px; border-radius:8px; background:linear-gradient(135deg,#8b89ff,#7c3aed); display:flex; align-items:center; justify-content:center; }
.nav-logo-icon span { font-family:'Orbitron',sans-serif; font-size:14px; font-weight:900; color:#fff; }
.nav-logo-text { font-family:'Orbitron',sans-serif; font-size:14px; font-weight:700; color:#fff; }
.nav-lang-wrap { position:relative; }
.lang-current { background:rgba(139,137,255,0.1); border:1px solid rgba(139,137,255,0.2); color:#ccc; padding:6px 12px; border-radius:8px; font-size:12px; cursor:pointer; font-family:inherit; display:flex; align-items:center; gap:4px; }
.lang-current:hover { background:rgba(139,137,255,0.2); }
.lang-menu { position:absolute; top:100%; right:0; background:rgba(20,20,40,0.95); backdrop-filter:blur(20px); border:1px solid rgba(139,137,255,0.2); border-radius:10px; padding:8px; display:flex; flex-direction:column; gap:4px; min-width:120px; }
.lang-option { background:none; border:none; color:#ccc; padding:8px 12px; border-radius:6px; font-size:13px; cursor:pointer; font-family:inherit; text-align:left; }
.lang-option:hover { background:rgba(139,137,255,0.15); color:#fff; }
.lang-option.active { background:rgba(139,137,255,0.25); color:#fff; }
.nav-tabs { display:flex; overflow-x:auto; padding:0 8px 8px; gap:2px; scrollbar-width:none; -ms-overflow-style:none; }
.nav-tabs::-webkit-scrollbar { display:none; }
.nav-tab { flex:1; min-width:48px; text-align:center; padding:6px 4px; color:#666; font-size:10px; text-decoration:none; white-space:nowrap; border-radius:8px; transition:all 0.2s; }
.nav-tab:hover { color:#8b89ff; background:rgba(139,137,255,0.05); }
.nav-tab.on { color:#8b89ff; background:rgba(139,137,255,0.1); }
.nav-tab i { font-size:16px; display:block; margin-bottom:2px; }
@media(max-width:380px){ .nav-tab{font-size:9px;} }
`;
const styleEl = document.createElement('style');
styleEl.textContent = navCSS;
document.head.appendChild(styleEl);
