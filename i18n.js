// ========================================
// 王牌学院 ACE Academy - 多语言核心系统
// 支持：中文zh / 英文en / 日文ja / 韩文ko / 西班牙文es
// 用法：所有文字用 <span data-i18n="key">默认中文</span>
//       JS里用 t('key') 获取翻译
// 语言切换：setLang('en') 存localStorage，刷新后生效
// ========================================

const LANGS = [
    {code:'zh', name:'中文', flag:'🇨🇳'},
    {code:'en', name:'English', flag:'🇺🇸'},
    {code:'ja', name:'日本語', flag:'🇯🇵'},
    {code:'ko', name:'한국어', flag:'🇰🇷'},
    {code:'es', name:'Español', flag:'🇪🇸'},
];

const DEFAULT_LANG = 'zh';

function getLang() {
    const l = localStorage.getItem('ace_lang');
    return LANGS.some(x => x.code === l) ? l : DEFAULT_LANG;
}

function setLang(l) {
    localStorage.setItem('ace_lang', l);
    location.reload();
}

function t(key) {
    const lang = getLang();
    const dict = I18N[key];
    if (!dict) return key;
    return dict[lang] || dict.zh || key;
}

// ========================================
// 翻译字典
// ========================================
const I18N = {
    // ===== 通用 =====
    home: {zh:'首页', en:'Home', ja:'ホーム', ko:'홈', es:'Inicio'},
    courses: {zh:'课程', en:'Courses', ja:'コース', ko:'강의', es:'Cursos'},
    learning: {zh:'学习', en:'Learn', ja:'学習', ko:'학습', es:'Aprender'},
    trade: {zh:'交易', en:'Trade', ja:'取引', ko:'거래', es:'Comercio'},
    promote: {zh:'推广', en:'Promote', ja:'推進', ko:'홍보', es:'Promover'},
    profile: {zh:'我的', en:'Profile', ja:'マイ', ko:'내정보', es:'Perfil'},
    login: {zh:'登录', en:'Login', ja:'ログイン', ko:'로그인', es:'Acceder'},
    register: {zh:'注册', en:'Register', ja:'登録', ko:'가입', es:'Registro'},
    back: {zh:'返回', en:'Back', ja:'戻る', ko:'뒤로', es:'Volver'},
    next: {zh:'下一步', en:'Next', ja:'次へ', ko:'다음', es:'Siguiente'},
    submit: {zh:'提交', en:'Submit', ja:'送信', ko:'제출', es:'Enviar'},
    cancel: {zh:'取消', en:'Cancel', ja:'キャンセル', ko:'취소', es:'Cancelar'},
    confirm: {zh:'确认', en:'Confirm', ja:'確認', ko:'확인', es:'Confirmar'},
    refresh: {zh:'刷新', en:'Refresh', ja:'更新', ko:'새로고침', es:'Actualizar'},
    copy: {zh:'复制', en:'Copy', ja:'コピー', ko:'복사', es:'Copiar'},
    enter_platform: {zh:'进入学习', en:'Enter', ja:'入場', ko:'입장', es:'Entrar'},

    // ===== 首页 =====
    brand_name: {zh:'王牌学院', en:'ACE Academy', ja:'ACE学院', ko:'ACE 아카데미', es:'ACE Academia'},
    tagline: {zh:'学技能 · 拿证书 · 赚代币', en:'Learn · Certify · Earn', ja:'学ぶ · 証明 · 稼ぐ', ko:'배우다 · 인증 · 벌다', es:'Aprende · Certifica · Gana'},
    start_learn: {zh:'开始学习', en:'Start Learning', ja:'学習開始', ko:'학습시작', es:'Empezar'},
    browse_courses: {zh:'浏览课程', en:'Browse Courses', ja:'コース一覧', ko:'강의보기', es:'Ver Cursos'},
    ai_planner: {zh:'专属学习规划师', en:'Learning Planner'},
    ai_planner_start: {zh:'开始规划', en:'Start Planning'},
    ai_planner_desc: {zh:'定制专属学习路径 · 快速拿到证书', en:'Custom learning path · Get certified fast'},
    no_account_reg: {zh:'没有账户？注册', en:'No account? Register', ja:'アカウントなし？登録', ko:'계정 없음? 가입', es:'Sin cuenta? Regístrate'},
    have_account_login: {zh:'已有账户？登录', en:'Have account? Login', ja:'アカウントあり？ログイン', ko:'계정 있음? 로그인', es:'Con cuenta? Accede'},
    stat_directions: {zh:'课程方向', en:'Directions', ja:'方向', ko:'분야', es:'Direcciones'},
    stat_courses: {zh:'门课程', en:'Courses', ja:'コース', ko:'강의', es:'Cursos'},
    stat_total_ace: {zh:'ACE总量', en:'ACE Total', ja:'ACE総量', ko:'ACE총량', es:'ACE Total'},
    course_directions: {zh:'课程方向', en:'Course Directions', ja:'コース方向', ko:'강의분야', es:'Direcciones'},
    platform_features: {zh:'平台特性', en:'Platform Features', ja:'機能', ko:'플랫폼 특징', es:'Características'},

    // 方向
    dir_ai: {zh:'AI应用', en:'AI Application', ja:'AI応用', ko:'AI응용', es:'IA Aplicada'},
    dir_ai_desc: {zh:'ChatGPT · AI绘画 · AI视频', en:'ChatGPT · AI Art · AI Video', ja:'ChatGPT · AI画像 · AI動画', ko:'ChatGPT · AI그림 · AI영상', es:'ChatGPT · Arte IA · Video IA'},
    dir_block: {zh:'区块链/Web3', en:'Blockchain/Web3', ja:'ブロックチェーン', ko:'블록체인', es:'Blockchain'},
    dir_block_desc: {zh:'钱包 · DeFi · 智能合约', en:'Wallet · DeFi · Contracts', ja:'ウォレット · DeFi · 契約', ko:'지갑 · DeFi · 계약', es:'Wallet · DeFi · Contratos'},
    dir_ecom: {zh:'跨境电商', en:'E-commerce', ja:'越境EC', ko:'전자상거래', es:'E-commerce'},
    dir_ecom_desc: {zh:'亚马逊 · Shopee · TikTok', en:'Amazon · Shopee · TikTok', ja:'Amazon · Shopee · TikTok', ko:'Amazon · Shopee · TikTok', es:'Amazon · Shopee · TikTok'},
    dir_mkt: {zh:'数字营销', en:'Digital Marketing', ja:'デジタル営業', ko:'디지털 마케팅', es:'Marketing Digital'},
    dir_mkt_desc: {zh:'社媒 · 内容 · 私域', en:'Social · Content · Private', ja:'SNS · 内容 · 私域', ko:'소셜 · 콘텐츠 · 프라이빗', es:'Social · Contenido · Privado'},
    dir_code: {zh:'编程入门', en:'Programming', ja:'プログラミング', ko:'프로그래밍', es:'Programación'},
    dir_code_desc: {zh:'Python · 网页 · AI编程', en:'Python · Web · AI Coding', ja:'Python · Web · AI', ko:'Python · 웹 · AI', es:'Python · Web · IA'},

    // 特性
    feat_ai: {zh:'AI定制学习方案', en:'AI Custom Plan', ja:'AIカスタムプラン', ko:'AI 맞춤 계획', es:'Plan IA Personalizado'},
    feat_ai_d: {zh:'5个问题了解需求，AI生成专属路径', en:'5 questions, AI builds your path', ja:'5問でAIが専用プラン', ko:'5문항으로 AI 맞춤 경로', es:'5 preguntas, IA crea tu plan'},
    feat_cert: {zh:'链上证书', en:'On-chain Cert', ja:'オンチェーン証明書', ko:'온체인 인증서', es:'Certificado'},
    feat_cert_d: {zh:'NFT证书，永久不可篡改', en:'NFT cert, immutable', ja:'NFT証明書、不変', ko:'NFT 인증서, 불변', es:'NFT, inmutables'},
    feat_token: {zh:'学习即赚', en:'Learn to Earn', ja:'学んで稼ぐ', ko:'배우고 번다', es:'Aprende y Gana'},
    feat_token_d: {zh:'买课送ACE，学完释放', en:'Get ACE, release as you learn', ja:'ACE付与、学んで解放', ko:'ACE 지급, 학습으로 해제', es:'Obtén ACE, libéralo'},
    feat_promo: {zh:'推广赚钱', en:'Promote to Earn', ja:'紹介で稼ぐ', ko:'홍보로 번다', es:'Promociona y Gana'},
    feat_promo_d: {zh:'直推拿现金，团队拿ACE', en:'Referrals cash, team ACE', ja:'紹介で現金、チームACE', ko:'추천 현금, 팀 ACE', es:'Referidos en USDT, equipo en ACE'},
    feat_safe: {zh:'资金安全', en:'Secure Funds', ja:'資金安全', ko:'자금 안전', es:'Fondos Seguros'},
    feat_safe_d: {zh:'合约自动执行，LP永久销毁', en:'Smart contracts, LP burned', ja:'自動実行、LP焼却', ko:'자동 실행, LP 소각', es:'Contratos, LP quemado'},
    feat_charity: {zh:'公益基金', en:'Charity', ja:'公益基金', ko:'공익 기금', es:'Caridad'},
    feat_charity_d: {zh:'每笔收入1%帮助学员', en:'1% helps students', ja:'収入1%が支援', ko:'수익 1% 학생 지원', es:'1% ayuda estudiantes'},

    // ===== 登录注册 =====
    ref_address: {zh:'推荐人钱包地址', en:'Referral Wallet', ja:'紹介者アドレス', ko:'추천인 주소', es:'Wallet Referente'},
    ref_placeholder: {zh:'输入推荐人地址 0x...', en:'Enter referral 0x...', ja:'紹介者アドレス 0x...', ko:'추천인 주소 0x...', es:'Ingresa referente 0x...'},
    ref_required: {zh:'必须通过推荐人邀请注册', en:'Referral required to register', ja:'紹介者経由が必要', ko:'추천인 필요', es:'Referencia requerida'},
    ref_auto: {zh:'有推荐链接会自动填入', en:'Auto-filled if you have link', ja:'リンクで自動入力', ko:'링크가 있으면 자동', es:'Autocompleta con enlace'},
    slide_verify: {zh:'向右滑动完成验证', en:'Slide to verify', ja:'右へスライド', ko:'오른쪽으로 드래그', es:'Desliza para verificar'},
    verified: {zh:'验证通过', en:'Verified', ja:'認証完了', ko:'인증완료', es:'Verificado'},
    step1: {zh:'输入推荐人地址', en:'Referral Address', ja:'紹介者アドレス', ko:'추천인 주소', es:'Dirección Referente'},
    step2: {zh:'安全验证', en:'Security', ja:'セキュリティ', ko:'보안 인증', es:'Seguridad'},
    step3: {zh:'连接钱包', en:'Connect Wallet', ja:'ウォレット接続', ko:'지갑 연결', es:'Conectar Wallet'},
    step4: {zh:'注册完成', en:'Complete', ja:'登録完了', ko:'가입 완료', es:'Completado'},
    connect_wallet: {zh:'连接钱包并授权', en:'Connect Wallet', ja:'ウォレット接続', ko:'지갑 연결', es:'Conectar'},
    reg_success: {zh:'注册成功', en:'Registration Success', ja:'登録成功', ko:'가입 성공', es:'Registro Exitoso'},
    login_success: {zh:'登录成功', en:'Login Success', ja:'ログイン成功', ko:'로그인 성공', es:'Acceso Exitoso'},
    wallet_addr: {zh:'钱包地址', en:'Wallet Address', ja:'ウォレット', ko:'지갑 주소', es:'Wallet'},
    user_id: {zh:'用户ID', en:'User ID', ja:'ID', ko:'사용자 ID', es:'ID'},
    referrer: {zh:'推荐人', en:'Referrer', ja:'紹介者', ko:'추천인', es:'Referente'},
    bound: {zh:'已绑定', en:'Bound', ja:'済み', ko:'연결됨', es:'Vinculado'},
    sign_to_login: {zh:'签名授权登录', en:'Sign to Login', ja:'署名ログイン', ko:'서명 로그인', es:'Firmar'},
    welcome_back: {zh:'欢迎回到王牌学院', en:'Welcome back to ACE Academy', ja:'おかえりなさい', ko:'환영합니다', es:'Bienvenido'},

    // ===== 课程库 =====
    course_library: {zh:'课程库', en:'Course Library', ja:'コース一覧', ko:'강의 목록', es:'Biblioteca'},
    free_resources: {zh:'5大方向 · 25门课程 · 免费优质资源', en:'5 Directions · 25 Courses · Free Resources', ja:'5方向 · 25コース · 無料', ko:'5분야 · 25강의 · 무료', es:'5 · 25 · Gratis'},
    learning_method: {zh:'学习方式', en:'Learning:', ja:'学習方式:', ko:'학습 방식:', es:'Método:'},
    watch_video: {zh:'观看视频', en:'Video', ja:'動画', ko:'영상', es:'Video'},
    practice: {zh:'实操', en:'Practice', ja:'実践', ko:'실습', es:'Práctica'},
    coding: {zh:'写代码', en:'Code', ja:'コード', ko:'코딩', es:'Código'},
    exam: {zh:'考试', en:'Exam', ja:'試験', ko:'시험', es:'Examen'},
    beginner: {zh:'入门', en:'Beginner', ja:'入門', ko:'입문', es:'Básico'},
    intermediate: {zh:'进阶', en:'Intermediate', ja:'中級', ko:'중급', es:'Intermedio'},
    advanced: {zh:'高级', en:'Advanced', ja:'上級', ko:'고급', es:'Avanzado'},

    // ===== 学习 =====
    learning_progress: {zh:'学习进度', en:'Progress', ja:'進捗', ko:'진행률', es:'Progreso'},
    total_hours: {zh:'总时长', en:'Hours', ja:'総時間', ko:'총시간', es:'Horas'},
    tokens_released: {zh:'已释放代币', en:'Tokens Released', ja:'解放トークン', ko:'해제 토큰', es:'Liberados'},
    course_list: {zh:'课程列表', en:'Course List', ja:'コース一覧', ko:'강의 목록', es:'Lista'},
    complete: {zh:'完成', en:'Complete', ja:'完了', ko:'완료', es:'Completar'},
    review: {zh:'复习', en:'Review', ja:'復習', ko:'복습', es:'Revisar'},
    in_progress: {zh:'进行中', en:'In Progress', ja:'進行中', ko:'진행중', es:'Progreso'},
    locked: {zh:'未解锁', en:'Locked', ja:'未解放', ko:'미해제', es:'Bloqueado'},
    take_exam: {zh:'参加考试', en:'Take Exam', ja:'試験', ko:'시험', es:'Examen'},

    // ===== 交易 =====
    ace_price: {zh:'ACE价格', en:'ACE Price', ja:'ACE価格', ko:'ACE 가격', es:'Precio ACE'},
    buy_ace: {zh:'买入ACE', en:'Buy ACE', ja:'買う', ko:'구매', es:'Comprar'},
    sell_ace: {zh:'卖出ACE', en:'Sell ACE', ja:'売る', ko:'판매', es:'Vender'},
    pool: {zh:'底池', en:'Pool', ja:'プール', ko:'풀', es:'Pool'},
    burned: {zh:'已销毁', en:'Burned', ja:'焼却', ko:'소각', es:'Quemado'},
    recent_trades: {zh:'最近交易', en:'Trades', ja:'取引', ko:'거래', es:'Operaciones'},

    // ===== 推广 =====
    my_ref_link: {zh:'我的推荐链接', en:'My Referral Link', ja:'紹介リンク', ko:'내 추천 링크', es:'Mi Enlace'},
    income: {zh:'收入', en:'Income', ja:'収入', ko:'수입', es:'Ingresos'},
    team: {zh:'团队', en:'Team', ja:'チーム', ko:'팀', es:'Equipo'},
    upgrade_partner: {zh:'升级合伙人', en:'Be Partner', ja:'パートナー', ko:'파트너', es:'Ser Socio'},
    level_learner: {zh:'学者', en:'Learner'},
    level_mentor: {zh:'导师', en:'Mentor'},
    level_scholar: {zh:'学士', en:'Scholar'},
    level_master: {zh:'硕士', en:'Master'},
    level_chancellor: {zh:'院长', en:'Chancellor'},
    ambassador: {zh:'大使', en:'Ambassador', ja:'アンバサダー', ko:'앰버서더', es:'Embajador'},

    // ===== 我的 =====
    my_assets: {zh:'我的资产', en:'My Assets', ja:'資産', ko:'내 자산', es:'Mis Activos'},
    staking: {zh:'质押生息', en:'Staking', ja:'ステーキング', ko:'스테이킹', es:'Staking'},
    my_certs: {zh:'我的证书', en:'My Certs', ja:'証明書', ko:'내 자격증', es:'Mis Certificados'},
    benefits: {zh:'持有权益', en:'Benefits', ja:'特典', ko:'혜택', es:'Beneficios'},
    refund: {zh:'退课', en:'Refund', ja:'返金', ko:'환불', es:'Reembolso'},

    // ===== 管理后台 =====
    admin_panel: {zh:'管理后台', en:'Admin Panel', ja:'管理', ko:'관리', es:'Admin'},
    global_stats: {zh:'全网统计', en:'Stats', ja:'統計', ko:'통계', es:'Estadísticas'},
    fund_wallets: {zh:'资金钱包', en:'Wallets', ja:'ウォレット', ko:'지갑', es:'Wallets'},
    permissions: {zh:'权限', en:'Permissions', ja:'権限', ko:'권한', es:'Permisos'},
    actions: {zh:'操作', en:'Actions', ja:'操作', ko:'작업', es:'Acciones'},

    // ===== 考试 =====
    start_exam: {zh:'开始考试', en:'Start Exam', ja:'開始', ko:'시작', es:'Empezar'},
    exam_passed: {zh:'考试通过！', en:'Passed!', ja:'合格！', ko:'합격!', es:'¡Aprobado!'},
    exam_failed: {zh:'未通过', en:'Failed', ja:'不合格', ko:'불합격', es:'Reprobado'},
    retry: {zh:'重新考试', en:'Retry', ja:'再試', ko:'재응시', es:'Reintentar'},

    // ===== 至尊套餐 =====
    premium_plan: {zh:'至尊套餐', en:'Premium Plan', ja:'プレミアム', ko:'프리미엄', es:'Premium'},
    all_access: {zh:'全部课程终身有效', en:'All courses lifetime', ja:'全コース永久', ko:'전체 강의 평생', es:'Todos los cursos'},

    // 补充翻译
    total_supply: {zh:'总量', en:'Supply', ja:'総量', ko:'총량', es:'Suministro'},
    expected_gain: {zh:'预计获得', en:'Expected', ja:'獲得予定', ko:'예상 획득', es:'Esperado'},
    fee: {zh:'手续费', en:'Fee', ja:'手数料', ko:'수수료', es:'Comisión'},
    burn_share: {zh:'销毁1.5%', en:'Burn 1.5%', ja:'焼却1.5%', ko:'소각1.5%', es:'Quemar 1.5%'},
    charity_share: {zh:'公益0.5%', en:'Charity 0.5%', ja:'公益0.5%', ko:'공익0.5%', es:'Caridad 0.5%'},
    cert_title: {zh:'AI应用认证', en:'AI Application Cert', ja:'AI応用証明書', ko:'AI 응용 인증', es:'Cert IA'},
    stake_amount: {zh:'质押', en:'Stake', ja:'ステーク', ko:'트테이크', es:'Stake'},
    annual_rate: {zh:'年化', en:'APR', ja:'年利', ko:'연수익', es:'APR'},
    holding_benefits: {zh:'持有权益', en:'Benefits', ja:'特典', ko:'혜택', es:'Beneficios'},
    coupon95: {zh:'课程9.5折', en:'Course 5% off', ja:'コース5%OFF', ko:'강의 5%할인', es:'Curso -5%'},
    unlock5000: {zh:'持有5,000 ACE解锁', en:'Unlock at 5,000 ACE', ja:'5,000 ACEで解放', ko:'5,000 ACE 해제', es:'Desbloquea con 5,000'},
    my_cert: {zh:'我的证书', en:'My Certs', ja:'マイ証明書', ko:'내 자격증', es:'Mis Certificados'},
    direct_referrals: {zh:'直推人数', en:'Direct Count', ja:'直接紹介', ko:'직추천', es:'Directos'},
    team_members: {zh:'团队总人数', en:'Team Total', ja:'チーム数', ko:'팀 총원', es:'Total Equipo'},
    team_rev: {zh:'团队业绩', en:'Team Revenue', ja:'チーム業績', ko:'팀 실적', es:'Ingresos Equipo'},
    current_level: {zh:'当前级别', en:'Current Level', ja:'現レベル', ko:'현재 등급', es:'Nivel'},
    next_level: {zh:'下一级', en:'Next Level', ja:'次のレベル', ko:'다음 등급', es:'Siguiente'},
    upgrade_to: {zh:'升级为', en:'Upgrade to', ja:'へ昇格', ko:'로 승격', es:'Subir a'},
    role: {zh:'身份', en:'Role', ja:'役割', ko:'역할', es:'Rol'},
    learn_now: {zh:'开始学习', en:'Start', ja:'開始', ko:'시작', es:'Empezar'},
    apply_refund: {zh:'申请退课', en:'Apply Refund', ja:'返金申請', ko:'환불 신청', es:'Solicitar'},
    admin_panel_2: {zh:'管理后台', en:'Admin Panel', ja:'管理', ko:'관리', es:'Admin'},
    global_stats_2: {zh:'全网统计', en:'Stats', ja:'統計', ko:'통계', es:'Estadísticas'},

    // 个人中心-动态值
    available_ace: {zh:'可用ACE', en:'Available ACE', ja:'利用可能ACE', ko:'사용가능 ACE', es:'ACE Disponible'},
    locked_ace: {zh:'锁定ACE', en:'Locked ACE', ja:'ロックACE', ko:'잠금 ACE', es:'ACE Bloqueado'},
    student_role: {zh:'学员', en:'Student', ja:'学生', ko:'학생', es:'Estudiante'},
    released_pct: {zh:'已释放', en:'Released', ja:'解放済み', ko:'해제됨', es:'Liberado'},
    courses_points: {zh:'5门课 · 95分', en:'5 courses · 95 pts', ja:'5コース · 95点', ko:'5강의 · 95점', es:'5 cursos · 95 pts'},
    days_90: {zh:'90天', en:'90 days', ja:'90日', ko:'90일', es:'90 días'},
    discount_community: {zh:'课程9折+社群', en:'10% off + Community', ja:'コース10%OFF+コミュニティ', ko:'강의 10%할인+커뮤니티', es:'10% off + Comunidad'},

    // 学习中心-课程名
    c_ai_basic: {zh:'AI人人通 — 什么是AI', en:'AI Essentials', ja:'AI基礎', ko:'AI 기초', es:'Fundamentos IA'},
    c_chatgpt: {zh:'ChatGPT实战 — 提示词', en:'ChatGPT Practice', ja:'ChatGPT実践', ko:'ChatGPT 실전', es:'Práctica ChatGPT'},
    c_ai_img: {zh:'AI做图片 — MJ/SD', en:'AI Image — MJ/SD', ja:'AI画像', ko:'AI 이미지', es:'Imagen IA'},
    c_ai_video: {zh:'AI做视频 — 剪映AI', en:'AI Video — CapCut', ja:'AI動画', ko:'AI 영상', es:'Video IA'},
    c_ai_office: {zh:'AI办公 — PPT/Excel', en:'AI Office — PPT/Excel', ja:'AIオフィス', ko:'AI 오피스', es:'Oficina IA'},
    completed: {zh:'已完成', en:'Completed', ja:'完了済み', ko:'완료됨', es:'Completado'},
    hours_short: {zh:'小时', en:'hrs', ja:'時間', ko:'시간', es:'hrs'},
    learned: {zh:'已学', en:'Learned', ja:'学習済', ko:'학습', es:'Aprendido'},

    // 修读档案(学分制)
    credit_total: {zh:'总学分', en:'Total Credits', ja:'総単位', ko:'총학점', es:'Créditos'},
    credit_progress: {zh:'整体进度', en:'Overall Progress', ja:'全体進捗', ko:'전체진행', es:'Progreso'},
    learn_deadline: {zh:'学习周期截止', en:'Milestone Deadline', ja:'学習締切', ko:'학습 마감', es:'Plazo'},
    days_left: {zh:'天后', en:'days left', ja:'日後', ko:'일 후', es:'días'},
    delay_hint: {zh:'到期未修满80学分，未释放代币将降速', en:'If not complete in time, token release slows', ja:'期日未達成でトークン減速', ko:'기한 미달 시 토큰 감속', es:'Token ralentiza'},
    can_cert: {zh:'可拿证', en:'Ready', ja:'合格可能', ko:'인증 가능', es:'Listo'},
    need_credit: {zh:'差', en:'need', ja:'あと', ko:'부족', es:'necesita'},
    continue_learn: {zh:'继续学习', en:'Continue Learning', ja:'学習続行', ko:'학습 계속', es:'Seguir'},

    // ==== 交易补充 ====
    ace_balance: {zh:'ACE余额',en:'ACE Balance',ja:'ACE残高',ko:'ACE 잔액',es:'Saldo ACE'},
    usdt_balance: {zh:'USDT余额',en:'USDT Balance',ja:'USDT残高',ko:'USDT 잔액',es:'Saldo USDT'},
    pay_amount: {zh:'支付金额',en:'Amount',ja:'金額',ko:'금액',es:'Monto'},
    trade_success: {zh:'交易成功', en:'Success'},
    buy_success: {zh:'买入成功', en:'Buy complete'},
    sell_success: {zh:'卖出成功', en:'Sell complete'},
    confirm_buy: {zh:'确认买入', en:'Confirm Buy'},
    confirm_sell: {zh:'确认卖出', en:'Confirm Sell'},
    insufficient: {zh:'余额不足', en:'Insufficient balance'},
    enter_amount: {zh:'请输入数量', en:'Enter amount'},
    cancel_trade: {zh:'取消交易', en:'Cancel'},
    pay_usdt: {zh:'支付', en:'Pay'},
    receive_ace: {zh:'获得ACE', en:'Receive ACE'},
    sell_ace_amount: {zh:'卖出数量', en:'Sell amount'},
    receive_usdt: {zh:'获得USDT', en:'Receive USDT'},
    balance: {zh:'余额', en:'Balance'},
    continue_trade: {zh:'继续交易', en:'Continue'},
    you_have: {zh:'当前持有', en:'You have'},
    after_trade: {zh:'交易后', en:'After trade'},
    gas_tip: {zh:'(模拟演示，未连接合约)', en:'(Demo, no contract linked)'},
    sell_amount_in: {zh:'卖出数量',en:'Sell Amount',ja:'売却数',ko:'판매량',es:'Vender'},
    my_assets_3: {zh:'我的资产',en:'My Assets',ja:'マイ資産',ko:'내자산',es:'Mis Activos'},
    // ===== 个人中心交互 =====
    cert_detail: {zh:'证书详情', en:'Cert Detail'},
    cert_no: {zh:'证书编号', en:'Cert No.'},
    cert_courses: {zh:'修读课程', en:'Courses'},
    cert_score: {zh:'成绩', en:'Score'},
    cert_issued: {zh:'颁发日期', en:'Issued'},
    cert_valid: {zh:'链上验证有效', en:'Chain-verified'},
    verify_cert: {zh:'验证证书', en:'Verify'},
    cert_chain: {zh:'已上链 · 可验证', en:'On-chain · Verified'},
    view_cert: {zh:'查看证书', en:'View Cert'},
    stake_amount2: {zh:'质押数量', en:'Amount'},
    stake_days: {zh:'选择期限', en:'Duration'},
    stake_day30: {zh:'30天·年化8%', en:'30D·8%'},
    stake_day90: {zh:'90天·年化10%', en:'90D·10%'},
    stake_day180: {zh:'180天·年化14%', en:'180D·14%'},
    stake_interest: {zh:'预计年化收益', en:'Est. yield'},
    stake_success: {zh:'质押成功', en:'Staked'},
    stake_period: {zh:'质押期限', en:'Period'},
    select_days: {zh:'请选择期限', en:'Select duration'},
    refund_title: {zh:'申请退课', en:'Apply Refund'},
    refund_reason: {zh:'退课原因', en:'Reason'},
    refund_plan: {zh:'退课方案选择', en:'Plan'},
    refund_option1: {zh:'退ACE币', en:'Refund in ACE'},
    refund_option2: {zh:'退USDT(扣10%)', en:'Refund in USDT (-10%)'},
    refund_agree: {zh:'退课需扣除已学课程费用', en:'Paid courses deducted'},
    refund_submit: {zh:'提交申请', en:'Submit'},
    refund_success: {zh:'退课申请已提交', en:'Refund submitted'},
    refund_tip: {zh:'处理时间1-3个工作日', en:'Processing 1-3 days'},
    day30: {zh:'30天', en:'30 days'},
    day90: {zh:'90天', en:'90 days'},
    day180: {zh:'180天', en:'180 days'},
    days_unit: {zh:'天', en:'days'},
    staked_cta: {zh:'确认质押', en:'Confirm'},
    available: {zh:'可用', en:'Available'},
    current_stake: {zh:'已质押', en:'Staked'},
    edit: {zh:'修改', en:'Edit'},
    close: {zh:'关闭', en:'Close'},
    hint: {zh:'提示', en:'Hint'},
    done: {zh:'完成', en:'Done'},
    ok: {zh:'确定', en:'OK'},
    note: {zh:'说明', en:'Note'},
    reward: {zh:'奖励', en:'Reward'},
    confirm_str: {zh:'确认', en:'Confirm'},
    view_detail: {zh:'查看详情', en:'Details'},
    select_reason: {zh:'请选择退课原因', en:'Select a reason'},
    refund_reason1: {zh:'课程不感兴趣', en:'Not interested'},
    refund_reason2: {zh:'学习时间不足', en:'No time'},
    refund_reason3: {zh:'重复购买', en:'Duplicate purchase'},
    refund_reason4: {zh:'其他原因', en:'Other'},
    success: {zh:'成功', en:'Success'},
    need_login: {zh:'请先登录', en:'Please login'},
    demo_modal: {zh:'(模拟演示)', en:'(Demo)'},
    price: {zh:'价格',en:'Price',ja:'価格',ko:'가격',es:'Precio'},
    holder: {zh:'持有人', en:'Holder'},
    benefit_tip: {zh:'持币越多，权益越高。ACE可在交易市场购买。', en:'Hold more ACE for higher benefits.'},

    // ==== 管理补充 ====
    market_mgmt: {zh:'做市管理',en:'Market Mgmt',ja:'市場管理',ko:'시장관리',es:'Mercado'},
    promo_stats: {zh:'推广统计',en:'Promo Stats',ja:'推進統計',ko:'홍보통계',es:'Promoción'},
    contracts: {zh:'合约地址',en:'Contracts',ja:'契約',ko:'컨트랙트',es:'Contratos'},
    platform_fund: {zh:'平台运营USDT',en:'Platform USDT',ja:'運営USDT',ko:'플랫폼 USDT',es:'USDT'},
    protection_fund: {zh:'护盘基金',en:'Protection',ja:'保護基金',ko:'보호기금',es:'Protección'},
    topup_protection: {zh:'补充护盘基金',en:'Top Up',ja:'補充',ko:'보충',es:'Recargar'},
    monthly_buyback: {zh:'月度回购',en:'Buyback',ja:'買戻し',ko:'매수',es:'Recompra'},
    emergency_pause: {zh:'紧急暂停',en:'Pause',ja:'停止',ko:'정지',es:'Pausar'},
    question_count: {zh:'题目数量',en:'Questions',ja:'問題数',ko:'문제수',es:'Preguntas'},
    passing_score: {zh:'及格分数',en:'Pass',ja:'合格点',ko:'합격점',es:'Aprob'},
    exam_duration: {zh:'考试时长',en:'Duration',ja:'時間',ko:'시간',es:'Duración'},
};

// ========================================
// 应用翻译：把所有 data-i18n 的元素填充
// ========================================
function applyI18n() {
    const lang = getLang();
    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        const dict = I18N[key];
        if (dict) {
            el.textContent = dict[lang] || dict.zh || key;
        }
    });
    document.querySelectorAll('[data-i18n-ph]').forEach(el => {
        const key = el.getAttribute('data-i18n-ph');
        const dict = I18N[key];
        if (dict) {
            el.placeholder = dict[lang] || dict.zh || key;
        }
    });
    document.documentElement.lang = lang;
}

// 页面加载后自动应用
document.addEventListener('DOMContentLoaded', function() {
    applyI18n();
    syncLangSelects();
});
window.addEventListener('load', function() {
    setTimeout(function(){applyI18n();syncLangSelects();}, 50);
});

// 同步所有语言下拉框显示当前语言
function syncLangSelects() {
    const lang = getLang();
    document.querySelectorAll('.lang-select, select.lang').forEach(sel => {
        sel.value = lang;
    });
}
