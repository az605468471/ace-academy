#!/usr/bin/env python3
"""
ACE Academy v2 主网部署 - 全自动 (方案: owner=部署①初始化后转资金②)
用法: DEPLOY_PKEY=<部署①私钥> python3 deploy_v2_mainnet.py --go
      (不加 --go 为预览)
"""
import os, json, sys, time
from web3 import Web3
from eth_account import Account

PKEY = os.environ.get('DEPLOY_PKEY', '')
assert PKEY.startswith('0x'), "需要 DEPLOY_PKEY 环境变量(部署①私钥)"
go = '--go' in sys.argv

W2    = '0x0CF51a12d81019Ef823B52196c3c7841aF7A6671'  # 资金②
CHARITY = '0x133638070aEb48c8fB34FEdfcE3060B834029236'
PLATFORM= '0x470107129B0d247672De6fc14246544AFD49dA6D'
POOL    = '0x225E956272eC20C2eBAE91D38851a6Fb21B99240'
PROMO   = '0x5450f7617b074a2C2c935fD6Ce51eA46b17c2A4E'
USDT    = '0x55d398326f99059fF775485246999027B3197955'

RPC = 'https://bsc-dataseed1.binance.org'
w3 = Web3(Web3.HTTPProvider(RPC, request_kwargs={'timeout': 25}))
assert w3.is_connected()
ME = Account.from_key(PKEY).address
print(f"部署①: {ME} | BNB: {w3.eth.get_balance(ME)/10**18:.4f} | 模式:{'GO' if go else '预览'}")
print(f"资金②(owner目标): {W2}")

builds = json.load(open('contracts/all_builds_v2.json'))
# 短名→solidity合约名 映射
NAME_MAP = {'ACE':'ACEToken','Referral':'ACEReferral','Lock':'ACELock','Course':'ACECourse','Market':'ACEMarketManager','Cert':'ACECertificate'}

def deploy(nm, args, desc):
    c = w3.eth.contract(abi=builds[nm]['abi'], bytecode=builds[nm]['bin'])
    try:
        gas = c.constructor(*args).estimate_gas({'from': ME})
    except Exception as e:
        print(f"  ⚠️ {desc} 估算失败: {str(e)[:150]}"); return None
    gp = w3.eth.gas_price
    tx = c.constructor(*args).build_transaction({'from':ME,'nonce':w3.eth.get_transaction_count(ME),'gas':int(gas*1.2),'gasPrice':int(gp*1.15)})
    print(f"  [部署{desc}] gas~{gas} 成本~{gas*gp/10**18:.5f}BNB")
    if go:
        signed = w3.eth.account.sign_transaction(tx, PKEY)
        rtx = signed.raw_transaction
        h = w3.eth.send_raw_transaction(rtx.hex() if isinstance(rtx, bytes) else rtx)
        r = w3.eth.wait_for_transaction_receipt(h, timeout=180)
        assert r.status == 1, f"{desc} 失败"
        print(f"    ✓ {desc} -> {r.contractAddress}")
        return r.contractAddress
    else:
        print(f"    (预览) {desc} -> 将部署")
        return f"PRE_{nm}"

def call(contract, fn, args, desc):
    f = getattr(contract.functions, fn)(*args)
    try:
        gas = f.estimate_gas({'from': ME})
    except Exception as e:
        print(f"  ⚠️ {desc} 失败: {str(e)[:150]}"); return False
    gp = w3.eth.gas_price
    tx = f.build_transaction({'from':ME,'nonce':w3.eth.get_transaction_count(ME),'gas':int(gas*1.2),'gasPrice':int(gp*1.15)})
    print(f"  [调用{desc}] gas~{gas}")
    if go:
        signed = w3.eth.account.sign_transaction(tx, PKEY)
        rtx = signed.raw_transaction
        h = w3.eth.send_raw_transaction(rtx.hex() if isinstance(rtx, bytes) else rtx)
        r = w3.eth.wait_for_transaction_receipt(h, timeout=180)
        assert r.status == 1, f"{desc} 失败"
        print(f"    ✓ {desc}")
        return True
    else:
        print(f"    (预览) {desc}")
        return True

addr = {}
print("\n========== 1. 部署6合约 (owner=部署①) ==========")
a = deploy('ACEToken',[CHARITY, ME],'ACEToken'); addr['ACE']=a
if addr.get('ACE'):
    addr['Referral'] = deploy('ACEReferral',[addr['ACE'], ME],'Referral')
    addr['Lock']     = deploy('ACELock',[addr['ACE'], ME],'Lock')
    addr['Course']   = deploy('ACECourse',[addr['ACE'], USDT, PLATFORM, CHARITY, POOL, ME],'Course')
    addr['Market']   = deploy('ACEMarketManager',[addr['ACE'], USDT, PLATFORM, CHARITY, ME],'Market')
    addr['Cert']     = deploy('ACECertificate',[addr['ACE'], ME],'Cert')

if not go or not addr.get('ACE'):
    print("\n(预览结束。加 --go 且设 DEPLOY_PKEY 执行)")
    print(json.dumps(addr,indent=2))
    sys.exit(0)

ACE = w3.eth.contract(address=addr['ACE'], abi=builds['ACEToken']['abi'])
Course = w3.eth.contract(address=addr['Course'], abi=builds['ACECourse']['abi'])
Referral = w3.eth.contract(address=addr['Referral'], abi=builds['ACEReferral']['abi'])
Lock = w3.eth.contract(address=addr['Lock'], abi=builds['ACELock']['abi'])
Cert = w3.eth.contract(address=addr['Cert'], abi=builds['ACECertificate']['abi'])

print("\n========== 2. 初始化 - 合约互关联 ==========")
call(Course,'setReferralContract',[addr['Referral']],'Course->Referral')
call(Course,'setLockContract',[addr['Lock']],'Course->Lock')
call(Referral,'setCourseContract',[addr['Course']],'Referral->Course')
call(Lock,'setCourseContract',[addr['Course']],'Lock->Course')
call(Cert,'setCourseContract',[addr['Course']],'Cert->Course')

print("\n========== 3. 白名单(免手续费) ==========")
for cn in ['Referral','Lock','Course','Market','Cert']:
    call(ACE,'setExemptFromFee',[addr[cn],True],f'豁免{cn}')

print("\n========== 4. 预置官方推广钱包 ==========")
call(Referral,'registerReferral',[PROMO, ME],'预置官方推广(挂部署①下)')

print("\n========== 5. 1000万ACE分发 ==========")
U=10**18
for amt,to,nm in [
    (4000000, addr['Course'],'课程赠ACE池(Course)'),
    (1000000, addr['Referral'],'团队奖励池(Referral)'),
    (2000000, POOL,'底池(钱包⑤暂存)'),
    (1500000, W2,'团队锁定(留资金②)'),
    (1000000, W2,'大使池(留资金②)'),
    (500000, W2,'推广预留(25万自用+25推广)'),
]:
    call(ACE,'transfer',[to,amt*U],f'{nm} {amt}万')

print("\n========== 6. 转owner 全部→资金② ==========")
for cn in ['ACE','Referral','Lock','Course','Market','Cert']:
    c = w3.eth.contract(address=addr[cn], abi=builds[NAME_MAP[cn]]['abi'])
    call(c,'transferOwnership',[W2],f'{cn} owner->资金②')

# 保存部署信息
info={'network':'BSC Mainnet','contracts':addr,'wallets':{'deploy':ME,'ownerFund':W2,'charity':CHARITY,'platform':PLATFORM,'pool':POOL,'promo':PROMO}}
json.dump(info, open('contracts/deploy_v2_info.json','w'),indent=2)
print("\n🎉 部署完成! 信息已存 contracts/deploy_v2_info.json")
print("合约地址:")
for k,v in addr.items(): print(f"  {k}: {v}")
