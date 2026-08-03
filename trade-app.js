// ============================================
// 王牌学院 ACE Academy - 交易市场 (模拟版)
// 负责：买入/卖出的实时计算 + 确认 + 模拟成交 + 余额更新
// 目标：界面与交互与真实合约版一致
// 预留：buyACEOnChain / sellACEOnChain 供以后接入真实合约
// ============================================

// 模拟账户余额 (接入合约后改为链上余额)
let wallet = {
    ace: 2000,      // 持有 ACE
    usdt: 500       // 持有 USDT
};

// 模拟价格：1 ACE = 0.1 USDT
const ACE_PRICE = 0.1;

// 卖出费用比例
const SELL_FEE_RATE = 0.02;      // 手续费 2%
const SELL_BURN_RATE = 0.015;    // 销毁 1.5%
const SELL_CHARITY_RATE = 0.005; // 公益 0.5%

let pendingTrade = null; // 待确认的交易 {type:'buy'|'sell', pay, get, ...}

// ===== 工具：数字格式化 =====
function fmt(n, dec) {
    if (dec === undefined) dec = 2;
    return Number(n.toFixed(dec)).toLocaleString('en-US', {maximumFractionDigits: dec});
}

// ===== 初始化 =====
function initTradeApp() {
    updateBalances();
    // 输入监听：实时计算
    document.getElementById('buyInput').addEventListener('input', onBuyInput);
    document.getElementById('sellInput').addEventListener('input', onSellInput);
}

// ===== 更新余额显示 =====
function updateBalances() {
    document.getElementById('balAce').textContent = fmt(wallet.ace, 0);
    document.getElementById('balUsdt').textContent = fmt(wallet.usdt);
}

// ===== 买入输入 =====
function onBuyInput() {
    const val = parseFloat(document.getElementById('buyInput').value);
    const r = document.getElementById('buyResult');
    if (!val || val <= 0) { r.textContent = '-- ACE'; return; }
    const ace = val / ACE_PRICE;
    r.textContent = fmt(ace, 4) + ' ACE';
}

// ===== 卖出输入 =====
function onSellInput() {
    const val = parseFloat(document.getElementById('sellInput').value);
    const result = document.getElementById('sellResult');
    if (!val || val <= 0) {
        result.textContent = '-- USDT';
        document.getElementById('sellFee').textContent = '--';
        document.getElementById('sellBurn').textContent = '--';
        document.getElementById('sellCharity').textContent = '--';
        return;
    }
    const gross = val * ACE_PRICE;
    const fee = gross * SELL_FEE_RATE;
    const burn = gross * SELL_BURN_RATE;
    const charity = gross * SELL_CHARITY_RATE;
    const net = gross - fee - burn - charity;
    result.textContent = fmt(net) + ' USDT';
    document.getElementById('sellFee').textContent = fmt(fee) + ' U';
    document.getElementById('sellBurn').textContent = fmt(burn) + ' U';
    document.getElementById('sellCharity').textContent = fmt(charity) + ' U';
}

// ===== MAX按钮 =====
function setMax(side) {
    if (side === 'buy') {
        document.getElementById('buyInput').value = wallet.usdt;
        onBuyInput();
    } else {
        document.getElementById('sellInput').value = wallet.ace;
        onSellInput();
    }
}

// ===== 打开确认弹窗 =====
function confirmTrade(type) {
    const isBuy = type === 'buy';
    const input = parseFloat(document.getElementById(isBuy ? 'buyInput' : 'sellInput').value);
    if (!input || input <= 0) { showToast(getI18n('enter_amount')); return; }

    if (isBuy) {
        // 买入：input 是 USDT
        if (input > wallet.usdt) { showToast(getI18n('insufficient')); return; }
        const ace = input / ACE_PRICE;
        pendingTrade = { type: 'buy', usdt: input, ace: ace };
        document.getElementById('confirmTitle').innerHTML = '<i class="ph-fill ph-arrow-down-left"></i> ' + getI18n('confirm_buy');
        document.getElementById('confirmRow1L').textContent = getI18n('pay_usdt');
        document.getElementById('confirmRow1').textContent = fmt(input) + ' USDT';
        document.getElementById('confirmRow2L').textContent = getI18n('receive_ace');
        document.getElementById('confirmRow2').textContent = fmt(ace, 4) + ' ACE';
        // 买入无额外费用行
        document.getElementById('confirmRow3Wrap').style.display = 'none';
        document.getElementById('confirmRow4Wrap').style.display = 'none';
        document.getElementById('confirmRow5Wrap').style.display = 'none';
        document.getElementById('confirmNote').textContent = '1 ACE = ' + ACE_PRICE + ' USDT';
    } else {
        // 卖出：input 是 ACE
        if (input > wallet.ace) { showToast(getI18n('insufficient')); return; }
        const gross = input * ACE_PRICE;
        const fee = gross * SELL_FEE_RATE;
        const burn = gross * SELL_BURN_RATE;
        const charity = gross * SELL_CHARITY_RATE;
        const net = gross - fee - burn - charity;
        pendingTrade = { type: 'sell', ace: input, usdt: net, fee: fee, burn: burn, charity: charity };
        document.getElementById('confirmTitle').innerHTML = '<i class="ph-fill ph-arrow-up-right"></i> ' + getI18n('confirm_sell');
        document.getElementById('confirmRow1L').textContent = getI18n('sell_ace_amount');
        document.getElementById('confirmRow1').textContent = fmt(input, 4) + ' ACE';
        document.getElementById('confirmRow2L').textContent = getI18n('receive_usdt');
        document.getElementById('confirmRow2').textContent = fmt(net) + ' USDT';
        document.getElementById('confirmRow3Wrap').style.display = 'flex';
        document.getElementById('confirmRow4Wrap').style.display = 'flex';
        document.getElementById('confirmRow5Wrap').style.display = 'flex';
        document.getElementById('confirmRow3').textContent = fmt(fee) + ' U';
        document.getElementById('confirmRow4').textContent = fmt(burn) + ' U';
        document.getElementById('confirmRow5').textContent = fmt(charity) + ' U';
        document.getElementById('confirmNote').textContent = '手续费2% · 销毁1.5% · 公益0.5%';
    }
    document.getElementById('confirmOverlay').classList.add('show');
}

// ===== 执行交易 =====
function executeTrade() {
    if (!pendingTrade) return;
    const t = pendingTrade;

    // ★ 真实合约入口预留：以后改这里
    // const contractResult = isBuy ? buyACEOnChain(t.usdt) : sellACEOnChain(t.ace);
    // if (!contractResult.ok) return;

    // 模拟成交：更新余额
    if (t.type === 'buy') {
        wallet.usdt -= t.usdt;
        wallet.ace += t.ace;
        // 显示成功
        document.getElementById('successTitle').innerHTML = getI18n('buy_success');
        document.getElementById('successSub').innerHTML =
            '买入 ' + fmt(t.ace, 4) + ' ACE<br>支付 ' + fmt(t.usdt) + ' USDT';
    } else {
        wallet.ace -= t.ace;
        wallet.usdt += t.usdt;
        document.getElementById('successTitle').innerHTML = getI18n('sell_success');
        document.getElementById('successSub').innerHTML =
            '卖出 ' + fmt(t.ace, 4) + ' ACE<br>获得 ' + fmt(t.usdt) + ' USDT';
    }
    document.getElementById('successBal').innerHTML =
        getI18n('after_trade') + '：<br>' +
        'ACE <b>' + fmt(wallet.ace, 0) + '</b> · USDT <b>' + fmt(wallet.usdt) + '</b>';

    updateBalances();
    // 清空输入
    document.getElementById('buyInput').value = '';
    document.getElementById('sellInput').value = '';
    document.getElementById('buyResult').textContent = '-- ACE';
    document.getElementById('sellResult').textContent = '-- USDT';
    document.getElementById('sellFee').textContent = '--';
    document.getElementById('sellBurn').textContent = '--';
    document.getElementById('sellCharity').textContent = '--';

    closeOverlay('confirmOverlay');
    document.getElementById('successOverlay').classList.add('show');
    pendingTrade = null;
}

// ===== 关闭弹窗 =====
function closeOverlay(id) {
    document.getElementById(id).classList.remove('show');
    pendingTrade = null;
}

// ===== 轻提示 (Toast) =====
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

// ===== 获取当前语言文案 =====
function getI18n(key) {
    const dict = (typeof I18N !== 'undefined') ? I18N[key] : null;
    if (!dict) return key;
    const lang = getLang();
    return dict[lang] || dict.zh || key;
}

// ============================================
// ★ 预留：以后接入真实合约时替换这里
// ============================================
/*
async function buyACEOnChain(usdtAmount) {
    // const tx = await aceContract.buy({ value: ... });
    // await tx.wait();
    return { ok: true };
}
async function sellACEOnChain(aceAmount) {
    // const tx = await aceContract.sell(aceAmount);
    // await tx.wait();
    return { ok: true };
}
*/
