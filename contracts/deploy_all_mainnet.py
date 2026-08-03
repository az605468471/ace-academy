#!/usr/bin/env python3
"""
ACE Academy 主网一体化部署 - 方案B (简化清晰版)
部署钱包①全程执行, 完成后owner转回资金钱包②。

用法: python3 deploy_all_mainnet.py     预览
      python3 deploy_all_mainnet.py --go 广播
"""
import json, sys
from web3 import Web3
from eth_account import Account

# ⚠️ 部署钱包私钥已从脚本移除，改用环境变量 DEPLOY_PKEY 传入，防止硬编码泄露
import os
PKEY2 = os.environ.get('DEPLOY_PKEY', '')
if not PKEY2:
    raise SystemExit("❌ 缺少私钥: 请设置环境变量 DEPLOY_PKEY (部署钱包①私钥, 仅用于链上签名)")
PKEY = PKEY2
RPC      = sys.argv[sys.argv.index('--rpc')+1] if '--rpc' in sys.argv else 'https://bsc-dataseed1.binance.org'
OWNER2   = '0x0CF51a12d81019Ef823B52196c3c7841aF7A6671'  # 资金钱包②
CHARITY  = '0x133638070aEb48c8fB34FEdfcE3060B834029236'
PLATFORM = '0x470107129B0d247672De6fc14246544AFD49dA6D'
POOL     = '0x225E956272eC20C2eBAE91D38851a6Fb21B99240'
PROMO    = '0x5450f7617b074a2C2c935fD6Ce51eA46b17c2A4E'
USDT     = '0x55d398326f99059fF775485246999027B3197955'

go = '--go' in sys.argv
w3 = Web3(Web3.HTTPProvider(RPC, request_kwargs={'timeout': 25}))
assert w3.is_connected()
ME = Account.from_key(PKEY).address
print(f"部署者①: {ME} | BNB: {w3.eth.get_balance(ME)/10**18:.5f} | 模式:{'GO执行' if go else '预览'}")
builds = json.load(open('all_builds_v2.json'))

def send(signed_tx, desc):
    if go:
        h = w3.eth.send_raw_transaction(signed_tx)
        r = w3.eth.wait_for_transaction_receipt(h, timeout=180)
        assert r.status==1, f"失败: {desc}"
        print(f"  ✓ {desc} | txid={h.hex()[:14]}.. | gas={r.gasUsed}")
        return r
    else:
        print(f"  (预览) {desc}")
        return None

def deploy_contract(name, args, desc):
    c = w3.eth.contract(abi=builds[name]['abi'], bytecode=builds[name]['bin'])
    try:
        gas = c.constructor(*args).estimate_gas({'from': ME})
    except Exception as e:
        print(f"  ⚠️ {desc} 估算失败: {str(e)[:120]}"); return None
    gp = w3.eth.gas_price
    tx = c.constructor(*args).build_transaction({'from':ME,'nonce':w3.eth.get_transaction_count(ME),'gas':int(gas*1.15),'gasPrice':int(gp*1.15)})
    print(f"  [部署{desc}] gas~{gas} 成本~{gas*gp/10**18:.5f}BNB")
    if go:
        signed = w3.eth.account.sign_transaction(tx, PKEY)
        r = send(signed.raw_transaction.hex() if isinstance(signed.raw_transaction, bytes) else signed.raw_transaction, f"部署{desc}")
        return r.contractAddress if r else None
    else:
        print(f"  (预览) 部署{desc} -> 将得到合约地址")
        return f"PREVIEW_{desc}"

def call(contract, func_name, args, desc):
    fn = contract.functions.__getattribute__(func_name)(*args)
    try:
        gas = fn.estimate_gas({'from': ME})
    except Exception as e:
        print(f"  ⚠️ {desc} 估算失败: {str(e)[:120]}"); return False
    gp = w3.eth.gas_price
    tx = fn.build_transaction({'from':ME,'nonce':w3.eth.get_transaction_count(ME),'gas':int(gas*1.2),'gasPrice':int(gp*1.15)})
    print(f"  [调用{desc}] gas~{gas} 成本~{gas*gp/10**18:.5f}BNB")
    if go:
        signed = w3.eth.account.sign_transaction(tx, PKEY)
        r = send(signed.raw_transaction.hex() if isinstance(signed.raw_transaction, bytes) else signed.raw_transaction, f"调用{desc}")
        return True
    else:
        print(f"  (预览) 调用{desc}")
        return True

# 收集地址字典
addr = {}
print("\n========== 1. 部署6合约 ==========")
a = deploy_contract('ACEToken', [CHARITY, ME], 'ACEToken')
if a: addr['ACEToken'] = a
if addr.get('ACEToken'):
    a = deploy_contract('ACEReferral', [addr['ACEToken'], ME], 'ACEReferral'); addr['ACEReferral']=a
    a = deploy_contract('ACELock', [addr['ACEToken'], ME], 'ACELock'); addr['ACELock']=a
    a = deploy_contract('ACECourse', [addr['ACEToken'], USDT, PLATFORM, CHARITY, POOL, ME], 'ACECourse'); addr['ACECourse']=a
    a = deploy_contract('ACEMarketManager', [addr['ACEToken'], USDT, PLATFORM, CHARITY, ME], 'ACEMarketManager'); addr['ACEMarketManager']=a
    a = deploy_contract('ACECertificate', [addr['ACEToken'], ME], 'ACECertificate'); addr['ACECertificate']=a

print("\n部署地址:", json.dumps(addr, indent=2))
if not go:
    print("\n⚠️ 预览模式。确认参数正确后加 --go 真正部署。")
    sys.exit(0)

# ===== 以下是 --go 执行路径 (依赖addr) =====
ACE = w3.eth.contract(address=addr['ACEToken'], abi=builds['ACEToken']['abi'])
RF  = w3.eth.contract(address=addr['ACEReferral'], abi=builds['ACEReferral']['abi'])
LK  = w3.eth.contract(address=addr['ACELock'], abi=builds['ACELock']['abi'])
CS  = w3.eth.contract(address=addr['ACECourse'], abi=builds['ACECourse']['abi'])
MK  = w3.eth.contract(address=addr['ACEMarketManager'], abi=builds['ACEMarketManager']['abi'])
CT  = w3.eth.contract(address=addr['ACECertificate'], abi=builds['ACECertificate']['abi'])

print("\n========== 2. 初始化 - 合约互关联 ==========")
call(CS, 'setReferralContract', [addr['ACEReferral']], 'Course->Referral')
call(CS, 'setLockContract', [addr['ACELock']], 'Course->Lock')
call(RF, 'setCourseContract', [addr['ACECourse']], 'Referral->Course')
call(LK, 'setCourseContract', [addr['ACECourse']], 'Lock->Course')
call(CT, 'setCourseContract', [addr['ACECourse']], 'Cert->Course')

print("\n========== 3. 初始化 - 白名单(免手续费) ==========")
for cn, a in addr.items():
    if cn != 'ACEToken':
        call(ACE, 'setExemptFromFee', [a, True], f'豁免{cn}')

print("\n========== 4. 初始化 - 预置官方推广钱包 ==========")
call(RF, 'registerReferral', [PROMO, ME], '预置官方推广钱包(挂ME下)')

print("\n========== 5. 初始化 - 添加课程 ==========")
call(CS, 'addCourse', [200*10**18], '添加课程1 (200U)')
call(CS, 'addCourse', [200*10**18], '添加课程2 (200U)')

print("\n========== 6. 分发1000万ACE (从部署钱包①) ==========")
U = 10**18
# ACE目前全在ME, 分发:
for amt, to, nm in [
    (4000000, addr['ACECourse'], '课程赠送池'),
    (1000000, addr['ACEReferral'], '团队奖励池(Referral)'),
    (2000000, POOL, '底池(暂存钱包⑤,不加)'),
]:
    call(ACE, 'transfer', [to, amt*U], f'{nm} {amt}万ACE')

print("\n========== 7. 把6合约owner转回资金钱包② ==========")
for cn, a in addr.items():
    cc = w3.eth.contract(address=a, abi=builds[cn]['abi'])
    call(cc, 'transferOwnership', [OWNER2], f'{cn} owner->资金②')

print("\n🎉 全部完成!")
print("owner(资金②):", OWNER2)
print("最终地址:", json.dumps(addr, indent=2))
