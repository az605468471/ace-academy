// ========================================
// 王牌学院 ACE Academy - 统一页面框架
// 提供：顶部栏(LOGO+语言下拉) + 底部导航
// 所有页面共用，保证多语言统一
// ========================================

// 标准的语言下拉选项HTML
function getLangSelectHTML() {
    return `
    <select class="lang-select" onchange="setLang(this.value)">
        <option value="zh">🇨🇳 中文</option>
        <option value="en">🇺🇸 English</option>
        <option value="ja">🇯🇵 日本語</option>
        <option value="ko">🇰🇷 한국어</option>
        <option value="es">🇪🇸 Español</option>
    </select>`;
}

// 顶部栏：LOGO + 标题 + 语言下拉
function header(titleKey, backTo) {
    const backHtml = backTo ? `<a href="${backTo}" class="back-link"><i class="ph ph-arrow-left"></i> <span data-i18n="back">返回</span></a>` : '';
    return `
    <div class="top-bar">
        <div class="top-left">
            <img src="images/ace-logo.png" class="top-logo" alt="ACE">
            <span class="top-title">ACE ACADEMY</span>
            ${titleKey ? `<span class="top-page" data-i18n="${titleKey}"></span>` : ''}
        </div>
        <div class="top-right">${backHtml}${getLangSelectHTML()}</div>
    </div>`;
}

// 底部导航
function bottomNav(active) {
    const items = [
        {key:'home', icon:'ph-fill ph-house', i18n:'home', href:'index.html'},
        {key:'course', icon:'ph ph-books', i18n:'courses', href:'course-library.html'},
        {key:'learn', icon:'ph-fill ph-graduation-cap', i18n:'learning', href:'learning.html'},
        {key:'trade', icon:'ph-fill ph-currency-btc', i18n:'trade', href:'trade.html'},
        {key:'promote', icon:'ph-fill ph-megaphone', i18n:'promote', href:'promote.html'},
        {key:'profile', icon:'ph-fill ph-user', i18n:'profile', href:'profile.html'},
    ];
    return `
    <div class="bottom-nav">
        ${items.map(it => `
            <a href="${it.href}" class="bn-item ${it.key===active?'on':''}">
                <i class="${it.icon}"></i><span data-i18n="${it.i18n}"></span>
            </a>`).join('')}
    </div>`;
}

// 统一的框架CSS（所有页面引入）
function injectFrameCSS() {
    if (document.getElementById('frameCSS')) return;
    const css = document.createElement('style');
    css.id = 'frameCSS';
    css.textContent = `
        /* 顶部栏 */
        .top-bar{display:flex;align-items:center;justify-content:space-between;padding:12px 16px;background:rgba(8,8,22,.95);backdrop-filter:blur(20px);border-bottom:1px solid rgba(139,137,255,.15);position:sticky;top:0;z-index:900;}
        .top-left{display:flex;align-items:center;gap:10px;}
        .top-logo{width:36px;height:36px;border-radius:10px;}
        .top-title{font-family:'Orbitron';font-size:13px;font-weight:800;letter-spacing:1px;color:#fff;}
        .top-page{font-size:13px;color:#8b89ff;font-weight:600;border-left:1px solid rgba(139,137,255,.2);padding-left:10px;}
        .top-right{display:flex;align-items:center;gap:10px;}
        .back-link{color:#8b89ff;font-size:12px;text-decoration:none;display:flex;align-items:center;gap:4px;}
        .lang-select{background:rgba(20,20,40,.8);border:1px solid rgba(139,137,255,.2);color:#ccc;padding:6px 10px;border-radius:8px;font-size:12px;outline:none;cursor:pointer;font-family:inherit;}
        .lang-select:hover{border-color:#8b89ff;}
        .lang-select option{background:#1a1a2e;color:#fff;}

        /* 底部导航 */
        .bottom-nav{position:fixed;bottom:0;left:0;right:0;z-index:999;background:rgba(10,10,26,.95);backdrop-filter:blur(20px);border-top:1px solid rgba(139,137,255,.2);display:flex;padding:8px 4px;}
        .bn-item{flex:1;text-align:center;padding:6px 2px;color:#666;font-size:10px;text-decoration:none;transition:color .2s;}
        .bn-item:hover{color:#8b89ff;}
        .bn-item.on{color:#8b89ff;}
        .bn-item i{font-size:20px;display:block;margin-bottom:2px;}
        body{padding-bottom:64px;}
    `;
    document.head.appendChild(css);
}

// 初始化登录后页面：注入CSS + 顶部栏 + 底部导航 + 应用翻译
function initFrame(titleKey, active, backTo) {
    injectFrameCSS();
    // 顶部
    const wrap = document.querySelector('.wrap') || document.body;
    const headerDiv = document.createElement('div');
    headerDiv.id = 'frameHeader';
    headerDiv.innerHTML = header(titleKey, backTo);
    wrap.insertBefore(headerDiv, wrap.firstChild);
    // 底部导航
    const navDiv = document.createElement('div');
    navDiv.innerHTML = bottomNav(active);
    document.body.appendChild(navDiv);
    // 应用翻译
    if (typeof applyI18n === 'function') {
        setTimeout(applyI18n, 50);
        setTimeout(syncLangSelects || function(){}, 60);
    }
}
