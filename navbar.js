// ========================================
// 王牌学院 ACE Academy - 统一导航栏组件
// 用法：在页面底部调用 createBottomNav('home')
// 登录后的所有页面显示底部导航栏，方便切换
// ========================================

function createBottomNav(active) {
    // 注入CSS
    if (!document.getElementById('bottomNavCSS')) {
        const css = document.createElement('style');
        css.id = 'bottomNavCSS';
        css.textContent = `
            .bottom-nav{position:fixed;bottom:0;left:0;right:0;z-index:999;background:rgba(10,10,26,.95);backdrop-filter:blur(20px);border-top:1px solid rgba(139,137,255,.2);display:flex;padding:8px 4px;}
            .bn-item{flex:1;text-align:center;padding:6px 2px;color:#666;font-size:10px;text-decoration:none;transition:color .2s;}
            .bn-item:hover{color:#8b89ff;}
            .bn-item.on{color:#8b89ff;}
            .bn-item i{font-size:20px;display:block;margin-bottom:2px;}
            body{padding-bottom:64px;}
        `;
        document.head.appendChild(css);
    }

    const items = [
        {key:'home', icon:'ph-fill ph-house', i18n:'home', href:'index.html'},
        {key:'course', icon:'ph ph-books', i18n:'courses', href:'course-library.html'},
        {key:'learn', icon:'ph-fill ph-graduation-cap', i18n:'learning', href:'learning.html'},
        {key:'trade', icon:'ph-fill ph-currency-btc', i18n:'trade', href:'trade.html'},
        {key:'promote', icon:'ph-fill ph-megaphone', i18n:'promote', href:'promote.html'},
        {key:'profile', icon:'ph-fill ph-user', i18n:'profile', href:'profile.html'},
    ];

    const nav = document.createElement('div');
    nav.className = 'bottom-nav';
    nav.id = 'mainBottomNav';
    nav.innerHTML = items.map(it => `
        <a href="${it.href}" class="bn-item ${it.key===active?'on':''}" data-key="${it.key}">
            <i class="${it.icon}"></i>
            <span data-i18n="${it.i18n}"></span>
        </a>
    `).join('');
    document.body.appendChild(nav);
    // 让i18n.js也翻译导航栏文字
    if (typeof applyI18n === 'function') applyI18n();
}
