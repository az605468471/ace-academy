// ============================================
// 王牌学院 ACE Academy - DApp 通用工具
// 依赖: ethers.js(CDN) + contracts-config.js + contracts-abi.js
// 提供统一的钱包连接、余额、学员数据读取
// ============================================

let currentWallet = null;

// 恢复已保存的钱包地址 (各页面加载时读取)
try {
    const saved = localStorage.getItem('ace_wallet');
    if (saved && saved.startsWith('0x')) currentWallet = saved;
} catch(e){}

// 连接钱包并返回地址
async function dappConnect() {
    if (!window.ethereum) { alert('未检测到钱包，请在 TP/MetaMask 内置浏览器中打开'); return null; }
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    currentWallet = accounts[0];
    dappSetAccount(currentWallet);
    await dappEnsureChain();
    return currentWallet;
}

async function dappEnsureChain() {
    try {
        await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: '0x' + CONTRACT_CONFIG.network.chainId.toString(16) }]
        });
    } catch (e) {
        if (e.code === 4902) {
            await window.ethereum.request({
                method: 'wallet_addEthereumChain',
                params: [{
                    chainId: '0x' + CONTRACT_CONFIG.network.chainId.toString(16),
                    chainName: CONTRACT_CONFIG.network.name,
                    nativeCurrency: { name: 'BNB', symbol: 'BNB', decimals: 18 },
                    rpcUrls: [CONTRACT_CONFIG.network.rpc],
                    blockExplorerUrls: [CONTRACT_CONFIG.network.explorer]
                }]
            });
        }
    }
}

function dappProvider() { return new ethers.providers.Web3Provider(window.ethereum); }

function dappC(name, signer) {
    const addr = CONTRACT_CONFIG.contracts[name];
    const abi = CONTRACT_ABIS[name];
    if (signer) { const p = dappProvider(); return new ethers.Contract(addr, abi, p.getSigner()); }
    return new ethers.Contract(addr, abi, new ethers.providers.JsonRpcProvider(CONTRACT_CONFIG.network.rpc));
}

async function dappRead(name, method, ...args) { return dappC(name)[method](...args); }

async function dappWrite(name, method, ...args) {
    const account = await dappConnect();
    if (!account) throw new Error('no wallet');
    const c = dappC(name, true);
    const tx = await c[method](...args);
    await tx.wait();
    return tx;
}

// 代币余额
async function dappTokenBalance(wallet, tokenAddr) {
    const erc20 = ['function balanceOf(address) view returns (uint256)', 'function decimals() view returns (uint8)'];
    const p = new ethers.providers.JsonRpcProvider(CONTRACT_CONFIG.network.rpc);
    const c = new ethers.Contract(tokenAddr, erc20, p);
    const bal = await c.balanceOf(wallet);
    const dec = await c.decimals();
    return { raw: bal, eth: ethers.utils.formatUnits(bal, dec) };
}

// ACE 余额
async function dappAceBalance(wallet) {
    return dappTokenBalance(wallet, CONTRACT_CONFIG.contracts.ACE);
}
// USDT 余额
async function dappUsdtBalance(wallet) {
    return dappTokenBalance(wallet, CONTRACT_CONFIG.usdt);
}

// 已连接地址
function dappAccount() { return currentWallet; }
function dappSetAccount(w) { currentWallet = w; try { localStorage.setItem('ace_wallet', w); } catch(e){} }
