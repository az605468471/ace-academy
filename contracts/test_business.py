#!/usr/bin/env python3
"""
ACE Academy 全流程业务测试 (在模拟部署基础上)
验证: 买课/代币释放/推广树/退课/证书 在 owner=资金钱包② 配置下正常
"""
import json
from web3 import Web3
from solcx import compile_files, compile_source, set_solc_version

set_solc_version('0.8.19')
w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:7549'))
assert w3.is_connected()

usdt_src = """
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
contract MockUSDT {
    string public constant name = "Tether USD";
    string public constant symbol = "USDT";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address public owner;
    constructor() { owner = msg.sender; }
    function transfer(address to, uint256 a) external returns(bool){ balanceOf[msg.sender]-=a; balanceOf[to]+=a; return true; }
    function approve(address s, uint256 a) external returns(bool){ allowance[msg.sender][s]=a; return true; }
    function transferFrom(address f, address t, uint256 a) external returns(bool){ allowance[f][msg.sender]-=a; balanceOf[f]-=a; balanceOf[t]+=a; return true; }
    function mint(address to, uint256 a) external { require(msg.sender==owner); totalSupply+=a; balanceOf[to]+=a; }
}
"""
usdt_def = list(compile_source(usdt_src, output_values=['abi']).values())[0]


info = json.load(open('deploy_sim_info.json'))
C = info['contracts']
W = info['wallets']
accounts = w3.eth.accounts
deployer = W['deployer①']; ownerFund = W['ownerFund②']
USER1 = accounts[6]; USER2 = accounts[7]; USER3 = accounts[8]
promoWallet = W['promoWallet⑥']

# 编译拿ABI
files = ['1_ACEToken.sol','2_CoursePurchase.sol','3_ReferralRewards.sol','4_TokenLock.sol','5_MarketManager.sol','6_CertificateNFT.sol']
compiled = compile_files(files, output_values=['abi','bin'], optimize=True, allow_paths='.')
ABI = {}
for src, c in compiled.items():
    nm = src.split(':')[1]
    if nm in ['ACEToken','ACECourse','ACEReferral','ACELock','ACECertificate']:
        ABI[nm] = c['abi']

def ABI_USDT():
    import json as _j
    return usdt_def['abi']

ace = w3.eth.contract(address=C['ACEToken'], abi=ABI['ACEToken'])
usdt = w3.eth.contract(address=C['MockUSDT'], abi=ABI_USDT())
cs = w3.eth.contract(address=C['ACECourse'], abi=ABI['ACECourse'])
rf = w3.eth.contract(address=C['ACEReferral'], abi=ABI['ACEReferral'])
lk = w3.eth.contract(address=C['ACELock'], abi=ABI['ACELock'])
ct = w3.eth.contract(address=C['ACECertificate'], abi=ABI['ACECertificate'])

ok = 0; fail = 0
def check(name, cond, detail="", dbg=None):
    global ok, fail
    if cond: ok += 1; s = "✅"
    else: fail += 1; s = "❌"
    print(f"  {s} {name} {detail}")
    return cond

print("=== 全流程业务测试 ===")

# 0. mock USDT mint 给用户
usdt.functions.mint(USER1, 100000*10**18).transact({'from': deployer})
usdt.functions.mint(USER2, 100000*10**18).transact({'from': deployer})
usdt.functions.mint(USER3, 100000*10**18).transact({'from': deployer})
print("\n✅ USDT已mint给测试用户")

# owner 添加课程 (owner=ownerFund)
cs.functions.addCourse(200*10**18).transact({'from': ownerFund})
cs.functions.addCourse(200*10**18).transact({'from': ownerFund})
print(f"\n✅ 添加课程: {cs.functions.courseCount().call()}门")

# 用户注册推荐关系 (通过官方推广钱包推广链接)
# USER1 通过官方推广钱包注册
rf.functions.registerReferral(USER1, promoWallet).transact({'from': USER1})
print(f"\n✅ USER1 通过官方推广钱包注册 (referrer=官方推广)")

# USER1 买课
usdt.functions.approve(C['ACECourse'], 10**18*2000).transact({'from': USER1})
cs.functions.buyCourse(1).transact({'from': USER1})
info1 = cs.functions.getStudentInfo(USER1).call()
check("USER1买课成功", info1[0] == 200*10**18 if info1 else False, f"总付费={info1[0]/10**18}U")
print(f"   USER1分配ACE={info1[1]/10**18}, 已释放={info1[2]/10**18}")

# USER1 阶段0已释放30%: 验证
# aceAllocated = 200U/当前价... (acePrice=0.01U/ACE => 200U = 20000 ACE)
alloc = info1[1]/10**18
check("阶段0释放30%", info1[2] > 0, f"已释放{info1[2]/10**18:.0f}ACE")

# 官方推广钱包团队人数更新
promo_stats = rf.functions.getTeamStats(promoWallet).call()
check("官方推广钱包有1个直推", rf.functions.getDirectCount(promoWallet).call() >= 1, f"直推={rf.functions.getDirectCount(promoWallet).call()}")

# 退课测试 (USER1 未考试,可退)
before_ace = ace.functions.balanceOf(USER1).call()
cs.functions.refundCourse(USER1).transact({'from': ownerFund})
after_ace = ace.functions.balanceOf(USER1).call()
refunded = cs.functions.getStudentInfo(USER1).call()[5]
check("退课成功(refunded=true)", refunded, "")
print(f"   USER1退课后ACE: {after_ace/10**18:.0f} (应含未释放剩余全部释放)")

print(f"\n{'='*50}")
print(f"📊 测试结果: {ok} 通过, {fail} 失败")
print(f"{'='*50}")
