// ============================================
// 王牌学院 链上证书 - 真实数据接入
// 连接钱包 → 读 Cert 合约的 NFT 证书 → 展示
// 依赖: dapp-tool.js + contracts-config.js + contracts-abi.js
// ============================================

let certTokens = [];

async function dappCertConnect() {
    const account = await dappConnect();
    if (!account) return;
    dappSetAccount(account);
    const c = document.getElementById('certConn');
    if (c) c.textContent = account.slice(0,8)+'...'+account.slice(-4);
    await loadUserCerts(account);
}

async function loadUserCerts(wallet) {
    const status = document.getElementById('certStatus');
    if (!status) return;
    // 先清空/显示加载
    try {
        const bal = await dappRead('Cert','balanceOf', wallet);
        const count = Number(bal);
        if (count === 0) {
            status.innerHTML = '<span style="color:#f87171">该钱包暂无链上证书。学完课程并通过考试后铸造。</span>';
            status.style.display='block';
            document.querySelector('.cert-wrap').style.opacity='0.3';
            return;
        }
        // 读所有 tokenId
        const tokens = await dappRead('Cert','getCertificatesByOwner', wallet);
        certTokens = tokens;
        // 展示第一个(最新)
        await showCert(certTokens[certTokens.length-1]);
        status.innerHTML = '<span style="color:#4ade80">共 '+count+' 张证书 · 已展示最新一张</span>';
        document.querySelector('.cert-wrap').style.opacity='1';
    } catch(e) {
        console.error(e);
        status.innerHTML = '<span style="color:#f87171">读取证书失败: '+ (e.message||'').slice(0,60) +'</span>';
    }
}

async function showCert(tokenId) {
    try {
        const c = await dappRead('Cert','getCertificate', tokenId);
        // (student, direction, coursesCompleted, examScore, issuedAt, certificateId)
        const student = c[0];
        const direction = c[1];
        const courses = Number(c[2]);
        const score = Number(c[3]);
        const issuedAt = new Date(Number(c[4])*1000).toISOString().slice(0,10);
        const certId = c[5];

        // 验证
        let valid=false;
        try { valid = await dappRead('Cert','verifyCertificate', tokenId); } catch(e){}

        // 填充
        setTxt('cDegree', direction || '--');
        setTxt('cNo', certId || ('#'+tokenId));
        setTxt('cHolder', student.slice(0,8)+'...'+student.slice(-4));
        setTxt('cDir', direction || '--');
        setTxt('cScore', score + ' 分');
        setTxt('cIssued', issuedAt);
        // 验证徽章
        const v = document.querySelector('.verify');
        if (v) v.innerHTML = valid
            ? '<i class="ph-fill ph-seal-check" style="font-size:18px"></i> 已上链 · 已验证有效 · Token#'+tokenId
            : '<i class="ph-fill ph-warning" style="font-size:18px"></i> 证书待验证';
    } catch(e) {
        console.error(e);
    }
}

function setTxt(id, v) { const el=document.getElementById(id); if(el) el.textContent=v; }
