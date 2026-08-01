#!/usr/bin/env python3
"""
ACE Academy 部署脚本
部署6个合约到Ganache模拟器
"""
import json, sys
from web3 import Web3
from solcx import compile_source, set_solc_version

set_solc_version('0.8.19')
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:7549"))
assert w3.is_connected(), "Ganache未连接"

accounts = w3.eth.accounts
print(f"✅ 连接Ganache成功，链ID: {w3.eth.chain_id}")
print(f"✅ 可用账户: {len(accounts)}个")

# 角色分配
deployer = accounts[0]       # 部署者
platformWallet = accounts[1] # 平台运营
charityWallet = accounts[2]  # 公益基金
poolWallet = accounts[3]     # 底池注入
userA = accounts[4]          # 推荐人
userB = accounts[5]          # 学员
userC = accounts[6]          # 学员
userD = accounts[7]          # 推广者
userE = accounts[8]          # 学员

# 读取合约源码
with open('/app/workspace/ark-academy/contracts/all_contracts.sol', 'r') as f:
    source = f.read()

print("\n📋 编译合约...")
compiled = compile_source(source, output_values=['abi', 'bin'], optimize=True, via_ir=True)
print("✅ 编译完成")

# 提取合约定义
contract_defs = {}
for key, val in compiled.items():
    name = key.split(':')[1].strip()
    contract_defs[name] = val

# ========== 部署MockUSDT ==========
print("\n🚀 部署MockUSDT...")
usdt_source = """
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
contract MockUSDT {
    string public name = "Tether USD";
    string public symbol = "USDT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address public owner;
    constructor() { owner = msg.sender; }
    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount; balanceOf[to] += amount; return true;
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount; return true;
    }
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount; balanceOf[from] -= amount; balanceOf[to] += amount; return true;
    }
    function mint(address to, uint256 amount) external {
        require(msg.sender == owner); totalSupply += amount; balanceOf[to] += amount;
    }
}
"""
usdt_compiled = compile_source(usdt_source, output_values=['abi', 'bin'])
usdt_def = list(usdt_compiled.values())[0]
USDT = w3.eth.contract(abi=usdt_def['abi'], bytecode=usdt_def['bin'])
tx = USDT.constructor().transact({'from': deployer})
receipt = w3.eth.wait_for_transaction_receipt(tx)
usdt_address = receipt.contractAddress
usdt = w3.eth.contract(address=usdt_address, abi=usdt_def['abi'])
print(f"✅ MockUSDT: {usdt_address}")

# 给测试用户mint USDT
for acc in [userA, userB, userC, userD, userE]:
    usdt.functions.mint(acc, 100000 * 10**18).transact({'from': deployer})
print("✅ 测试用户已mint 100000 USDT")

# ========== 1. 部署ACEToken ==========
print("\n🚀 部署ACEToken...")
ACE = w3.eth.contract(abi=contract_defs['ACEToken']['abi'], bytecode=contract_defs['ACEToken']['bin'])
tx = ACE.constructor(charityWallet).transact({'from': deployer})
receipt = w3.eth.wait_for_transaction_receipt(tx)
ace_address = receipt.contractAddress
ace = w3.eth.contract(address=ace_address, abi=contract_defs['ACEToken']['abi'])
print(f"✅ ACEToken: {ace_address}")
print(f"  总量: {ace.functions.totalSupply().call() / 10**18:,.0f} ACE")
print(f"  部署者余额: {ace.functions.balanceOf(deployer).call() / 10**18:,.0f} ACE")

# ========== 2. 部署ACELock ==========
print("\n🚀 部署ACELock...")
Lock = w3.eth.contract(abi=contract_defs['ACELock']['abi'], bytecode=contract_defs['ACELock']['bin'])
tx = Lock.constructor(ace_address).transact({'from': deployer})
receipt = w3.eth.wait_for_transaction_receipt(tx)
lock_address = receipt.contractAddress
print(f"✅ ACELock: {lock_address}")

# ========== 3. 部署ACEReferral ==========
print("\n🚀 部署ACEReferral...")
Referral = w3.eth.contract(abi=contract_defs['ACEReferral']['abi'], bytecode=contract_defs['ACEReferral']['bin'])
tx = Referral.constructor(ace_address).transact({'from': deployer})
receipt = w3.eth.wait_for_transaction_receipt(tx)
referral_address = receipt.contractAddress
print(f"✅ ACEReferral: {referral_address}")

# ========== 4. 部署ACECourse ==========
print("\n🚀 部署ACECourse...")
Course = w3.eth.contract(abi=contract_defs['ACECourse']['abi'], bytecode=contract_defs['ACECourse']['bin'])
tx = Course.constructor(ace_address, usdt_address, platformWallet, charityWallet, poolWallet).transact({'from': deployer})
receipt = w3.eth.wait_for_transaction_receipt(tx)
course_address = receipt.contractAddress
print(f"✅ ACECourse: {course_address}")

# ========== 5. 部署ACEMarketManager ==========
print("\n🚀 部署ACEMarketManager...")
Market = w3.eth.contract(abi=contract_defs['ACEMarketManager']['abi'], bytecode=contract_defs['ACEMarketManager']['bin'])
tx = Market.constructor(ace_address, usdt_address, platformWallet, charityWallet).transact({'from': deployer})
receipt = w3.eth.wait_for_transaction_receipt(tx)
market_address = receipt.contractAddress
print(f"✅ ACEMarketManager: {market_address}")

# ========== 6. 部署ACECertificate ==========
print("\n🚀 部署ACECertificate...")
Cert = w3.eth.contract(abi=contract_defs['ACECertificate']['abi'], bytecode=contract_defs['ACECertificate']['bin'])
tx = Cert.constructor(ace_address).transact({'from': deployer})
receipt = w3.eth.wait_for_transaction_receipt(tx)
cert_address = receipt.contractAddress
print(f"✅ ACECertificate: {cert_address}")

# ========== 配置合约关联 ==========
print("\n⚙️ 配置合约关联...")
course_contract = w3.eth.contract(address=course_address, abi=contract_defs['ACECourse']['abi'])
referral_contract = w3.eth.contract(address=referral_address, abi=contract_defs['ACEReferral']['abi'])
lock_contract = w3.eth.contract(address=lock_address, abi=contract_defs['ACELock']['abi'])

course_contract.functions.setReferralContract(referral_address).transact({'from': deployer})
course_contract.functions.setLockContract(lock_address).transact({'from': deployer})
print("  ✅ Course → Referral + Lock")

referral_contract.functions.setCourseContract(course_address).transact({'from': deployer})
print("  ✅ Referral → Course")

lock_contract.functions.setCourseContract(course_address).transact({'from': deployer})
print("  ✅ Lock → Course")

# Certificate的courseContract设置
cert_contract = w3.eth.contract(address=cert_address, abi=contract_defs['ACECertificate']['abi'])
cert_contract.functions.setCourseContract(course_address).transact({'from': deployer})
print("  ✅ Certificate → Course")

# 给Referral合约存ACE作为团队奖励池
ace.functions.transfer(referral_address, 500_000 * 10**18).transact({'from': deployer})
print(f"  ✅ Referral奖励池: 500,000 ACE")

# 给Course合约存ACE作为学员/推广者代币
ace.functions.transfer(course_address, 2_000_000 * 10**18).transact({'from': deployer})
print(f"  ✅ Course代币池: 2,000,000 ACE")

# Course合约设为ACE白名单（免手续费）
ace.functions.setExemptFromFee(course_address, True).transact({'from': deployer})
ace.functions.setExemptFromFee(lock_address, True).transact({'from': deployer})
ace.functions.setExemptFromFee(referral_address, True).transact({'from': deployer})
ace.functions.setExemptFromFee(market_address, True).transact({'from': deployer})
print("  ✅ 合约白名单设置")

# 添加课程
course_contract.functions.addCourse(200 * 10**18).transact({'from': deployer})  # 课程1: 200U
course_contract.functions.addCourse(200 * 10**18).transact({'from': deployer})  # 课程2: 200U
print("  ✅ 添加2门课程（各200U）")

# ========== 保存部署信息 ==========
deploy_info = {
    "network": "Ganache (localhost:7549)",
    "chain_id": w3.eth.chain_id,
    "contracts": {
        "ACEToken": ace_address,
        "ACECourse": course_address,
        "ACEReferral": referral_address,
        "ACELock": lock_address,
        "ACEMarketManager": market_address,
        "ACECertificate": cert_address,
        "MockUSDT": usdt_address
    },
    "wallets": {
        "deployer": deployer,
        "platformWallet": platformWallet,
        "charityWallet": charityWallet,
        "poolWallet": poolWallet
    },
    "users": {
        "userA": userA,
        "userB": userB,
        "userC": userC,
        "userD": userD,
        "userE": userE
    }
}

with open('/app/workspace/ark-academy/contracts/deploy_info.json', 'w') as f:
    json.dump(deploy_info, f, indent=2)

print("\n" + "="*60)
print("🎉 6个合约全部部署成功！")
print("="*60)
print(f"\n合约地址:")
for name, addr in deploy_info['contracts'].items():
    print(f"  {name}: {addr}")
print(f"\n部署信息已保存到 deploy_info.json")
