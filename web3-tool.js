// ============================================
// 王牌学院 ACE Academy - Web3 工具库
// 提供: 钱包连接 (MetaMask/TP) + 合约读/写
// 依赖: ethers.js (页面需引入), contracts-config.js
// ============================================

async function connectWallet() {
    if (!window.ethereum) {
        alert('请安装 MetaMask 或 TP 钱包');
        return null;
    }
    try {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        return accounts[0];
    } catch (e) {
        console.error('连接钱包失败', e);
        return null;
    }
}

// 切换到指定链
async function ensureChain(chainId) {
    const net = CONTRACT_CONFIG.network;
    try {
        await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: '0x' + net.chainId.toString(16) }]
        });
    } catch (e) {
        if (e.code === 4902) {
            await window.ethereum.request({
                method: 'wallet_addEthereumChain',
                params: [{
                    chainId: '0x' + net.chainId.toString(16),
                    chainName: net.name,
                    nativeCurrency: { name: 'BNB', symbol: 'BNB', decimals: 18 },
                    rpcUrls: [net.rpc],
                    blockExplorerUrls: [net.explorer]
                }]
            });
        }
    }
}

function getProvider() {
    return new ethers.providers.Web3Provider(window.ethereum);
}

// 获取合约实例 (signer=true 可写, 需钱包)
function getContract(name, withSigner = false) {
    const addr = CONTRACT_CONFIG.contracts[name];
    const abi = CONTRACT_ABIS[name];
    if (withSigner) {
        const provider = getProvider();
        const signer = provider.getSigner();
        return new ethers.Contract(addr, abi, signer);
    }
    const provider = new ethers.providers.JsonRpcProvider(CONTRACT_CONFIG.network.rpc);
    return new ethers.Contract(addr, abi, provider);
}

// 通用读函数
async function contractRead(name, method, ...args) {
    const c = getContract(name);
    return c[method](...args);
}

// 通用写函数 (需连接钱包)
async function contractWrite(name, method, ...args) {
    const c = await ensureSigner(name);
    const tx = await c[method](...args);
    await tx.wait();
    return tx;
}

async function ensureSigner(name) {
    const account = await connectWallet();
    if (!account) throw new Error('no wallet');
    await ensureChain(56);
    return getContract(name, true);
}

// ===== 具体业务函数 =====

// 获取 ACE 价格 (Course 合约 acePrice)
async function getAcePrice() {
    const p = await contractRead('Course', 'acePrice');
    return { raw: p, usdt: Number(ethers.utils.formatUnits(p, 18)) };
}

// 购买课程 (Course.buyCourse)
async function buyCourse(courseId) {
    const c = await ensureSigner('Course');
    const account = await connectWallet();
    // 先 approve USDT
    const usdt = new ethers.Contract(
        CONTRACT_CONFIG.usdt,
        ['function approve(address,uint256) returns (bool)'],
        c.signer
    );
    const coursePrice = await contractRead('Course', 'courses', courseId);
    const price = coursePrice[0];
    await (await usdt.approve(CONTRACT_CONFIG.contracts.Course, price)).wait();
    const tx = await c.buyCourse(courseId);
    await tx.wait();
    return tx;
}

// 读学员信息
async function getStudentInfo(wallet) {
    const r = await contractRead('Course', 'getStudentInfo', wallet);
    return {
        totalPaid: r[0], aceAllocated: r[1], aceReleased: r[2],
        coursesCompleted: r[3], examPassed: r[4], refunded: r[5]
    };
}

// 读推广者信息
async function getPromoterInfo(wallet) {
    const r = await contractRead('Course', 'getPromoterInfo', wallet);
    return { paid: r[0], aceAllocated: r[1], aceReleased: r[2], month: r[3], level: r[4], active: r[5] };
}

// 注册推荐关系
async function registerReferral(referrer) {
    const c = await ensureSigner('Referral');
    const tx = await c.registerReferral(await currentAccount(), referrer);
    await tx.wait();
    return tx;
}

async function currentAccount() {
    if (!window.ethereum) return null;
    const a = await window.ethereum.request({ method: 'eth_accounts' });
    return a[0] || null;
}
