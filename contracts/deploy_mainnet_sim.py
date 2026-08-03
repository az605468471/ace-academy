#!/usr/bin/env python3
"""
ACE Academy 主网模拟部署 + 全流程测试
链ID 56 (模拟BSC主网), Ganache 本地
角色用测试账户映射真实钱包，验证配置逻辑后用于主网部署

角色映射 (模拟用测试账户, 主网用真实地址):
  deployer      = 部署钱包① (只部署付gas)
  ownerFund     = 资金钱包② (owner + 1000万ACE + 管理权 + 25万)
  charity       = 公益钱包③
  platform      = 平台钱包④
  pool          = 底池钱包⑤
  promoWallet   = 官方推广钱包⑥ (推广之源)
  USER1..5      = 测试用户
"""
import json, sys, time
from web3 import Web3
from solcx import compile_files, compile_source, set_solc_version

set_solc_version('0.8.19')
w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:7549'))
assert w3.is_connected(), "Ganache未连接"
print(f"✅ 连接Ganache，链ID: {w3.eth.chain_id}，账户: {len(w3.eth.accounts)}个")

accounts = w3.eth.accounts
# 角色映射 (模拟)
deployer    = accounts[0]   # ①部署钱包
ownerFund   = accounts[1]   # ②资金钱包 (owner)
charity     = accounts[2]   # ③公益
platform    = accounts[3]   # ④平台
pool        = accounts[4]   # ⑤底池
promoWallet = accounts[5]   # ⑥官方推广钱包
USER1       = accounts[6]
USER2       = accounts[7]
USER3       = accounts[8]

print("\n=== 角色(模拟) ===")
print(f" deployer(①) : {deployer}")
print(f" ownerFund(②): {ownerFund}  <- owner+1000万ACE")
print(f" charity(③)  : {charity}")
print(f" platform(④) : {platform}")
print(f" pool(⑤)     : {pool}")
print(f" promoWallet(⑥): {promoWallet}  <- 官方推广")
print(f" USER1/2/3    : {USER1[:8]}.. {USER2[:8]}.. {USER3[:8]}..")

# 编译6个合约
print("\n📋 编译合约...")
files = ['1_ACEToken.sol','2_CoursePurchase.sol','3_ReferralRewards.sol','4_TokenLock.sol','5_MarketManager.sol','6_CertificateNFT.sol']
compiled = compile_files(files, output_values=['abi','bin'], optimize=True, allow_paths='.')
defs = {}
for src, c in compiled.items():
    defs[src.split(':')[1]] = c
print("✅ 编译完成:", list(defs.keys()))

# 部署 MockUSDT
print("\n🚀 部署 MockUSDT...")
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
uc = compile_source(usdt_src, output_values=['abi','bin'])
usdt_def = list(uc.values())[0]
UST = w3.eth.contract(abi=usdt_def['abi'], bytecode=usdt_def['bin'])
tx = UST.constructor().transact({'from': deployer})
usdt_addr = w3.eth.wait_for_transaction_receipt(tx).contractAddress
usdt = w3.eth.contract(address=usdt_addr, abi=usdt_def['abi'])
for u in [USER1, USER2, USER3]:
    usdt.functions.mint(u, 100000 * 10**18).transact({'from': deployer})
print(f"✅ MockUSDT: {usdt_addr}")

# ===== 部署6合约 (新构造: 加 _owner=ownerFund) =====
print("\n🚀 部署 ACEToken...")
ACE = w3.eth.contract(abi=defs['ACEToken']['abi'], bytecode=defs['ACEToken']['bin'])
tx = ACE.constructor(charity, ownerFund).transact({'from': deployer})
ace_addr = w3.eth.wait_for_transaction_receipt(tx).contractAddress
ace = w3.eth.contract(address=ace_addr, abi=defs['ACEToken']['abi'])
tot = ace.functions.totalSupply().call()/10**18
bal_owner = ace.functions.balanceOf(ownerFund).call()/10**18
bal_deployer = ace.functions.balanceOf(deployer).call()/10**18
print(f"✅ ACEToken: {ace_addr}")
print(f"   总量={tot:,.0f} | owner(②)={bal_owner:,.0f} | deployer(①)={bal_deployer:,.0f}")
assert bal_owner == tot and bal_deployer == 0, "❌ 1000万ACE必须全部在资金钱包②，部署钱包应为0"
print("   ✅ 关键验证通过: 1000万ACE在②，部署钱包①为0")

print("\n🚀 部署 ACEReferral...")
RF = w3.eth.contract(abi=defs['ACEReferral']['abi'], bytecode=defs['ACEReferral']['bin'])
tx = RF.constructor(ace_addr, ownerFund).transact({'from': deployer})
ref_addr = w3.eth.wait_for_transaction_receipt(tx).contractAddress
rf = w3.eth.contract(address=ref_addr, abi=defs['ACEReferral']['abi'])
print(f"✅ ACEReferral: {ref_addr}")
print(f"   owner={rf.functions.owner().call()} (应=资金钱包②)")

print("\n🚀 部署 ACELock...")
LK = w3.eth.contract(abi=defs['ACELock']['abi'], bytecode=defs['ACELock']['bin'])
tx = LK.constructor(ace_addr, ownerFund).transact({'from': deployer})
lock_addr = w3.eth.wait_for_transaction_receipt(tx).contractAddress
lk = w3.eth.contract(address=lock_addr, abi=defs['ACELock']['abi'])
print(f"✅ ACELock: {lock_addr}")

print("\n🚀 部署 ACECourse...")
CS = w3.eth.contract(abi=defs['ACECourse']['abi'], bytecode=defs['ACECourse']['bin'])
tx = CS.constructor(ace_addr, usdt_addr, platform, charity, pool, ownerFund).transact({'from': deployer})
course_addr = w3.eth.wait_for_transaction_receipt(tx).contractAddress
cs = w3.eth.contract(address=course_addr, abi=defs['ACECourse']['abi'])
print(f"✅ ACECourse: {course_addr}")

print("\n🚀 部署 ACEMarketManager...")
MK = w3.eth.contract(abi=defs['ACEMarketManager']['abi'], bytecode=defs['ACEMarketManager']['bin'])
tx = MK.constructor(ace_addr, usdt_addr, platform, charity, ownerFund).transact({'from': deployer})
market_addr = w3.eth.wait_for_transaction_receipt(tx).contractAddress
mk = w3.eth.contract(address=market_addr, abi=defs['ACEMarketManager']['abi'])
print(f"✅ ACEMarketManager: {market_addr}")

print("\n🚀 部署 ACECertificate...")
CT = w3.eth.contract(abi=defs['ACECertificate']['abi'], bytecode=defs['ACECertificate']['bin'])
tx = CT.constructor(ace_addr, ownerFund).transact({'from': deployer})
cert_addr = w3.eth.wait_for_transaction_receipt(tx).contractAddress
ct = w3.eth.contract(address=cert_addr, abi=defs['ACECertificate']['abi'])
print(f"✅ ACECertificate: {cert_addr}")

# ===== 配置合约关联 (owner=ownerFund 签名) =====
print("\n⚙️ 配置合约关联...")
cs.functions.setReferralContract(ref_addr).transact({'from': ownerFund})
cs.functions.setLockContract(lock_addr).transact({'from': ownerFund})
rf.functions.setCourseContract(course_addr).transact({'from': ownerFund})
lk.functions.setCourseContract(course_addr).transact({'from': ownerFund})
ct.functions.setCourseContract(course_addr).transact({'from': ownerFund})
print("  ✅ 合约互关联完成")

# ===== 预置官方推广钱包: 挂到ownerFund下成为推广根节点 =====
print("\n🌱 预置官方推广钱包...")
rf.functions.registerReferral(promoWallet, ownerFund).transact({'from': ownerFund})
print(f"  ✅ 官方推广钱包 {promoWallet[:10]}.. 已注册,referrer=ownerFund")

# ===== ACE白名单 (owner=ownerFund) =====
print("\n⚙️ 设置合约白名单(免手续费)...")
for addr, nm in [(course_addr,'Course'),(lock_addr,'Lock'),(ref_addr,'Referral'),(market_addr,'Market'),(cert_addr,'Cert')]:
    if not ace.functions.isExemptFromFee(addr).call():
        ace.functions.setExemptFromFee(addr, True).transact({'from': ownerFund})
print("  ✅ 白名单设置完成")

# ===== 代币分发 (owner=ownerFund 签名) =====
print("\n💰 代币分发 (1000万ACE)...")
# 分配账目
pool_alloc = {
    'Course_赠课池':    (4000000, course_addr),
    'Referral团队奖励':  (1000000, ref_addr),
    '大使赠送池留owner': (1000000, ownerFund),   # 暂留owner,需时再转
    'pool底池(暂存)':   (2000000, pool),
    '团队锁定留owner':  (1500000, ownerFund),     # 锁定池
    '推广预留':         (500000, ownerFund),      # 25万自用+25万推广,留owner
}
token_unit = 10**18
for nm, (amt, to) in pool_alloc.items():
    ace.functions.transfer(to, amt * token_unit).transact({'from': ownerFund})
    print(f"  ✅ {nm}: {amt:,.0f} ACE -> {to[:10]}..")

# 验证balance台账
print("\n📊 分发后余额台账(ownerFund):")
remaining = ace.functions.balanceOf(ownerFund).call()/10**18
print(f"  ownerFund(②)剩余: {remaining:,.0f} ACE  (应=25万自用+大使100万+推广25万留存+团队锁定150万)")
print(f"  course合约: {ace.functions.balanceOf(course_addr).call()/10**18:,.0f}")
print(f"  referral合约: {ace.functions.balanceOf(ref_addr).call()/10**18:,.0f}")
print(f"  pool(⑤): {ace.functions.balanceOf(pool).call()/10**18:,.0f}")

# ===== 保存部署信息 =====
info = {
    'network': 'BSC Mainnet Sim (chainId 56)',
    'contracts': {
        'ACEToken': ace_addr, 'ACECourse': course_addr,
        'ACEReferral': ref_addr, 'ACELock': lock_addr,
        'ACEMarketManager': market_addr, 'ACECertificate': cert_addr,
        'MockUSDT': usdt_addr
    },
    'wallets': {
        'deployer①': deployer, 'ownerFund②': ownerFund, 'charity③': charity,
        'platform④': platform, 'pool⑤': pool, 'promoWallet⑥': promoWallet
    }
}
json.dump(info, open('deploy_sim_info.json','w'), indent=2)
print("\n📁 模拟部署信息已保存 deploy_sim_info.json")
print("🎉 6合约部署 + 配置 + 分发全部完成！")
