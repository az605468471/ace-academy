// ============================================
// 王牌学院 ACE Academy - 个人中心交互 (模拟版)
// 功能：我的证书 / 质押生息 / 持有权益 / 申请退课
// 目标：界面与交互与真实合约版一致，预留链上接口
// ============================================

// 模拟资产
let profile = {
    availableAce: 720,      // 可用ACE
    stakedAce: 1000,        // 已质押ACE
    usdt: 500
};

// 质押状态
let staking = { days: 90, rate: 0.10, amount: 0 };
// 退课状态
let refund = { reason: 0, plan: 0 };

// 质押档位
const STAKE_PLANS = {
    30: 0.08,
    90: 0.10,
    180: 0.14
};

// ===== 初始化 =====
function initProfileApp() {
    updateProfileView();
    // 质押输入实时计算
    const stakeInput = document.getElementById('stakeInput');
    if (stakeInput) stakeInput.addEventListener('input', calcStakeInterest);
}

function updateProfileView() {
    const el = document.getElementById('pAvailable');
    if (el) el.textContent = profile.availableAce.toLocaleString();
}

// ===== 通用：i18n =====
function getI18n(key) {
    const dict = (typeof I18N !== 'undefined') ? I18N[key] : null;
    if (!dict) return key;
    const lang = getLang();
    return dict[lang] || dict.zh || key;
}

// ===== 通用：弹窗控制 =====
function closeOverlay(id) { document.getElementById(id).classList.remove('show'); }

// ============================================
// 1. 我的证书
// ============================================
function openCert() {
    document.getElementById('certOverlay').classList.add('show');
    // ★ 预留：以后可改为链上查询 NFT 证书
    // loadCertFromChain(certId);
}

// ============================================
// 2. 质押生息
// ============================================
function openStake() {
    document.getElementById('stkAvailable').textContent = profile.availableAce.toLocaleString();
    staking = { days: 90, rate: 0.10, amount: 0 };
    document.getElementById('stakeInput').value = '';
    document.querySelectorAll('#stakeOverlay .opt').forEach(o => o.classList.remove('on'));
    // 默认选90天
    document.querySelectorAll('#stakeOverlay .opt')[1].classList.add('on');
    calcStakeInterest();
    document.getElementById('stakeOverlay').classList.add('show');
    // ★ 预留：以后改为链上质押合约
    // openStakeOnChain();
}

function stakeMax() {
    document.getElementById('stakeInput').value = profile.availableAce;
    calcStakeInterest();
}

function pickDay(days, el) {
    el.parentElement.querySelectorAll('.opt').forEach(o => o.classList.remove('on'));
    el.classList.add('on');
    staking.days = days;
    staking.rate = STAKE_PLANS[days];
    calcStakeInterest();
}

function calcStakeInterest() {
    const amount = parseFloat(document.getElementById('stakeInput').value) || 0;
    staking.amount = amount;
    const rateMap = { 30: 0.08, 90: 0.10, 180: 0.14 };
    const rate = rateMap[staking.days] || 0.10;
    // 年化收益 = 本金 × 年化率（按天数折算）
    const days = staking.days;
    const interest = amount * rate * (days / 365);
    document.getElementById('stkDays').textContent = days;
    document.getElementById('stkRate').textContent = Math.round(rate * 100) + '%';
    document.getElementById('stkInterest').textContent = (amount > 0 ? interest.toFixed(2) : '--') + ' ACE';
}

function confirmStake() {
    const amount = staking.amount;
    if (!amount || amount <= 0) { showToast(getI18n('enter_amount')); return; }
    if (amount > profile.availableAce) { showToast(getI18n('insufficient')); return; }

    // 模拟质押
    // ★ 预留：以后改为链上质押
    // await stakeOnChain(amount, staking.days);

    profile.availableAce -= amount;
    profile.stakedAce += amount;
    updateProfileView();

    closeOverlay('stakeOverlay');
    const daysStr = {30:'30天',90:'90天',180:'180天'}[staking.days] || staking.days + '天';
    showOk(
        {},
        getI18n('stake_success'),
        '质押 ' + amount.toLocaleString() + ' ACE · ' + daysStr,
        '<b>' + getI18n('current_stake') + '</b> ' + profile.stakedAce.toLocaleString() + ' ACE<br>' +
        '<b>' + getI18n('annual_rate') + '</b> ' + Math.round(staking.rate*100) + '%'
    );
}

// ============================================
// 3. 持有权益
// ============================================
function openBenefits() {
    document.getElementById('benefitsOverlay').classList.add('show');
}

// ============================================
// 4. 申请退课
// ============================================
function openRefund() {
    refund = { reason: 0, plan: 0 };
    document.querySelectorAll('#refundOverlay .opt').forEach(o => o.classList.remove('on'));
    document.getElementById('refundOverlay').classList.add('show');
}

function pickReason(id, el) {
    el.parentElement.querySelectorAll('.opt').forEach(o => o.classList.remove('on'));
    el.classList.add('on');
    refund.reason = id;
}

function pickRefund(id, el) {
    el.parentElement.querySelectorAll('.opt').forEach(o => o.classList.remove('on'));
    el.classList.add('on');
    refund.plan = id;
    // 附加说明：退USDT扣10%
    if (id === 2) {
        // 更新提示
    }
}

function submitRefund() {
    if (!refund.reason) { showToast(getI18n('select_reason')); return; }
    if (!refund.plan) { showToast(getI18n('select_reason')); return; }

    // ★ 预留：以后改为链上退课合约
    // await requestRefundOnChain(refund.reason, refund.plan);

    closeOverlay('refundOverlay');
    const planText = refund.plan === 1 ? '退ACE' : '退USDT(扣10%)';
    showOk(
        {},
        getI18n('refund_success'),
        planText,
        getI18n('refund_tip')
    );
}

// ===== 成功弹窗 =====
function showOk(icon, title, sub, infoHtml) {
    document.getElementById('okTitle').innerHTML = title;
    document.getElementById('okSub').innerHTML = sub || '';
    const info = document.getElementById('okInfo');
    if (infoHtml) { info.style.display = 'block'; info.innerHTML = infoHtml; }
    else { info.style.display = 'none'; }
    document.getElementById('okOverlay').classList.add('show');
}

// ===== Toast =====
function showToast(msg) {
    let t = document.getElementById('toast');
    if (!t) {
        t = document.createElement('div');
        t.id = 'toast';
        t.style.cssText = 'position:fixed;left:50%;bottom:100px;transform:translateX(-50%);background:rgba(20,20,40,.95);color:#f87171;padding:10px 20px;border-radius:10px;font-size:13px;border:1px solid rgba(248,113,113,.4);z-index:2000;box-shadow:0 8px 30px rgba(0,0,0,.4);';
        document.body.appendChild(t);
    }
    t.textContent = msg;
    t.style.opacity = '1';
    clearTimeout(t._t);
    t._t = setTimeout(() => { t.style.opacity = '0'; }, 1800);
}

// ============================================
// ★ 预留：以后接入真实合约时替换以下注释函数
// ============================================
/*
async function loadCertFromChain(certId) { }
async function openStakeOnChain() { }
async function stakeOnChain(amount, days) {
    // const tx = await stakeContract.stake(amount, days);
    // await tx.wait();
    return { ok: true };
}
async function requestRefundOnChain(reason, plan) {
    // const tx = await courseContract.requestRefund(reason);
    return { ok: true };
}
*/
