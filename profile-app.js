// ============================================
// 王牌学院 ACE Academy - 个人中心 (真实链上版)
// 功能：连接钱包 / 真实余额 / 质押 / 退课 / 证书
// 依赖: dapp-tool.js + contracts-config.js + contracts-abi.js
// ============================================

let staking = { days: 90, amount: 0 };
let refundState = { reason: 0 };

const STAKE_RATES = { 30: 0.05, 90: 0.10, 180: 0.15 };

function initProfileApp() {
    const input = document.getElementById('stakeInput');
    if (input) input.addEventListener('input', calcStakeInterest);
    // 尝试读取已连接钱包
    if (window.ethereum) {
        window.ethereum.request({ method: 'eth_accounts' }).then(acc=>{
            if (acc && acc[0]) { dappSetAccount(acc[0]); loadRealProfile(acc[0]); }
        }).catch(()=>{});
    }
}

// ===== 连接钱包 + 加载真实数据 =====
async function dappProfileConnect() {
    const account = await dappConnect();
    if (!account) return;
    loadRealProfile(account);
}

async function loadRealProfile(wallet) {
    try {
        // 钱包地址
        const pWallet = document.getElementById('pWallet');
        if (pWallet) pWallet.textContent = wallet.slice(0,8)+'...'+wallet.slice(-4);
        const connText = document.getElementById('connText');
        if (connText) connText.textContent = '已连接';
        document.getElementById('pUserId').textContent = wallet.slice(0,6);

        // ACE / USDT 余额
        const ace = await dappAceBalance(wallet);
        const usdt = await dappUsdtBalance(wallet);
        document.getElementById('pAvailable').textContent = toFixed(ace.eth);
        document.getElementById('pUsdt').textContent = toFixed(usdt.eth, 2) + 'U';
        document.getElementById('pLocked').textContent = '0';

        // 学员信息 (已释放/分配)
        try {
            const stu = await dappRead('Course','getStudentInfo', wallet);
            const allocated = Number(ethers.utils.formatEther(stu.aceAllocated));
            const released = Number(ethers.utils.formatEther(stu.aceReleased));
            const refRaw = await dappRead('Referral','referrer', wallet);
            const ref = refRaw !== '0x0000000000000000000000000000000000000000' ? refRaw : null;
            document.getElementById('pReferrer').textContent = ref ? ref.slice(0,8)+'...'+ref.slice(-4) : '无';
            if (allocated > 0) {
                const pct = Math.min(100, Math.round(released/allocated*100));
                document.getElementById('pReleasedPct').textContent = '已释放 '+pct+'%';
                document.getElementById('pReleasedBar').style.width = pct+'%';
            }
        } catch(e) { /* user may not have records */ }

        // 证书数
        try {
            const certCount = await dappRead('Cert','balanceOf', wallet);
            document.querySelector('.cert-title-wrap .cnt').textContent = ' (' + certCount + ')';
        } catch(e){}
    } catch(e) {
        console.error('加载失败', e);
    }
}

// ===== 质押生息 (真实) =====
function openStake() {
    document.getElementById('stkAvailable').textContent = '加载中...';
    if (currentWallet) {
        dappAceBalance(currentWallet).then(b=>{
            document.getElementById('stkAvailable').textContent = toFixed(b.eth);
        }).catch(()=>{});
    } else {
        document.getElementById('stkAvailable').textContent = '请先连接钱包';
    }
    staking = { days: 90, amount: 0 };
    document.getElementById('stakeInput').value = '';
    const opts = document.querySelectorAll('#stakeOverlay .opt');
    opts.forEach(o=>o.classList.remove('on'));
    opts[1].classList.add('on');
    calcStakeInterest();
    openOverlay('stakeOverlay');
}

function stakeMax() {
    if (!currentWallet) return;
    dappAceBalance(currentWallet).then(b=>{ document.getElementById('stakeInput').value = Math.floor(Number(b.eth)); calcStakeInterest(); });
}

function pickDay(days, el) {
    document.querySelectorAll('#stakeOverlay .opt').forEach(o=>o.classList.remove('on'));
    el.classList.add('on');
    staking.days = days;
    calcStakeInterest();
}

function calcStakeInterest() {
    const amount = parseFloat(document.getElementById('stakeInput').value) || 0;
    staking.amount = amount;
    const rate = STAKE_RATES[staking.days] || 0.10;
    const interest = amount * rate * (staking.days / 365);
    document.getElementById('stkDays').textContent = staking.days;
    document.getElementById('stkRate').textContent = Math.round(rate*100)+'%';
    document.getElementById('stkInterest').textContent = amount>0 ? interest.toFixed(2)+' ACE' : '-- ACE';
}

async function confirmStake() {
    const amount = staking.amount;
    if (!amount || amount <= 0) { showToast(getI18n('enter_amount')); return; }
    if (!currentWallet) { showToast(getI18n('need_login')); return; }
    try {
        // approve ACE to Market
        const ace = dappC('ACE', true);
        const amt = ethers.utils.parseEther(String(amount));
        const approveTx = await ace.approve(CONTRACT_CONFIG.contracts.Market, amt);
        await approveTx.wait();
        // stake
        const market = dappC('Market', true);
        const tx = await market.stake(amt, staking.days);
        await tx.wait();
        closeOverlay('stakeOverlay');
        showOk({}, getI18n('stake_success'), '质押 '+amount+' ACE · '+staking.days+'天', '已上链生效');
        loadRealProfile(currentWallet);
    } catch(e) {
        console.error(e);
        showToast(e.message && e.message.includes('user rejected') ? '已取消' : '质押失败');
    }
}

// ===== 申请退课 (真实状态, owner执行) =====
function openRefund() {
    refundState = { reason: 0 };
    document.querySelectorAll('#refundOverlay .opt').forEach(o=>o.classList.remove('on'));
    const status = document.getElementById('refundStatus');
    const body = document.getElementById('refundBody');
    const denied = document.getElementById('refundDenied');

    if (!currentWallet) {
        status.innerHTML = '<div style="color:var(--red)">请先连接钱包查看退课状态</div>';
        body.style.display='none'; denied.style.display='none';
    } else {
        dappRead('Course','getStudentInfo', currentWallet).then(s=>{
            const allocated = Number(ethers.utils.formatEther(s.aceAllocated));
            const released = Number(ethers.utils.formatEther(s.aceReleased));
            const examPassed = s.examPassed, refunded = s.refunded;
            const unreleased = allocated - released;

            if (allocated <= 0) {
                status.innerHTML = '<div>暂无课程记录，无需退课</div>';
                body.style.display='none'; denied.style.display='none';
            } else if (examPassed && !refunded) {
                status.innerHTML = '<div class="dr" style="display:flex;justify-content:space-between;padding:4px 0"><span class="l">考试</span><b style="color:var(--green)">已通过(不可退)</b></div>';
                body.style.display='none'; denied.style.display='block';
            } else {
                status.innerHTML =
                    '<div class="dr" style="display:flex;justify-content:space-between;padding:4px 0"><span class="l">'+getI18n('released')+'</span><b>'+toFixed(released)+' ACE</b></div>'+
                    '<div class="dr" style="display:flex;justify-content:space-between;padding:4px 0"><span class="l">'+getI18n('unreleased')+'</span><b style="color:var(--green)">'+toFixed(unreleased)+' ACE</b></div>'+
                    '<div class="dr" style="display:flex;justify-content:space-between;padding:4px 0"><span class="l">'+getI18n('refund_amount')+'</span><b style="color:var(--green)">'+toFixed(unreleased)+' ACE</b></div>'+
                    '<div style="color:var(--dim);margin-top:6px;font-size:11px"><i class="ph ph-info"></i> 退课由管理员(owner)执行，申请后等待处理</div>';
                body.style.display='block'; denied.style.display='none';
            }
        }).catch(e=>{ status.innerHTML='<div style="color:var(--red)">查询失败</div>'; });
    }
    openOverlay('refundOverlay');
}

function pickReasonRefund(id, el) {
    document.querySelectorAll('#refundOverlay .opt').forEach(o=>o.classList.remove('on'));
    el.classList.add('on');
    refundState.reason = id;
}

function submitRefund() {
    if (!refundState.reason) { showToast(getI18n('select_reason')); return; }
    if (!currentWallet) { showToast(getI18n('need_login')); return; }
    // 退课由 owner(资金钱包②) 执行, 前端仅展示申请意向
    closeOverlay('refundOverlay');
    showOk({}, '退课申请', '已提交退课意向',
        '退课需管理员(资金钱包②)在链上执行 refundCourse。<br>未考试课程可退，将释放剩余 ACE。');
}

// ===== 证书 (真实) =====
async function openCert() {
    openOverlay('certOverlay');
    if (currentWallet) {
        try {
            const count = await dappRead('Cert','balanceOf', currentWallet);
            // 读第一个证书
            if (count > 0) {
                pendingLoader = true;
            }
        } catch(e){}
    }
}

// ===== 通用 =====
function openBenefits() {
    openOverlay('benefitsOverlay');
}

function getI18n(key) { const d=(typeof I18N!=='undefined')?I18N[key]:null; if(!d)return key; const l=getLang(); return d[l]||d.zh||key; }
function openOverlay(id){ document.getElementById(id).classList.add('show'); }
function closeOverlay(id){ document.getElementById(id).classList.remove('show'); }
function toFixed(v, d) { const n=Number(v); return n.toLocaleString('en-US',{maximumFractionDigits:(d===undefined?4:d)}); }
const showOk = (icon,title,sub,info)=>{ document.getElementById('okTitle').innerHTML=title;document.getElementById('okSub').innerHTML=sub||'';const i2=document.getElementById('okInfo');if(info){i2.style.display='block';i2.innerHTML=info;}else{i2.style.display='none';} openOverlay('okOverlay'); };
function showToast(msg){ let t=document.getElementById('toast'); if(!t){t=document.createElement('div');t.id='toast';t.style.cssText='position:fixed;left:50%;bottom:100px;transform:translateX(-50%);background:rgba(20,20,40,.95);color:#f87171;padding:10px 20px;border-radius:10px;font-size:13px;border:1px solid rgba(248,113,113,.4);z-index:2000;box-shadow:0 8px 30px rgba(0,0,0,.4);';document.body.appendChild(t);} t.textContent=msg;t.style.opacity='1';clearTimeout(t._t);t._t=setTimeout(()=>{t.style.opacity='0';},1800); }
