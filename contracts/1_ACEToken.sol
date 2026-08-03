// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ACE Token (Academy Excellence Token)
 * @dev 阿奇学院教育代币
 * 
 * 功能：
 * 1. BEP20标准代币，总量1000万枚，不可增发
 * 2. 卖出时2%手续费：1.5%销毁 + 0.5%公益基金
 * 3. 白名单豁免手续费（底池、合约自身等）
 * 4. 权限可丢弃（renounceOwnership）
 * 5. 紧急暂停功能
 */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ACEToken is IERC20 {
    string public constant name = "ACE Token";
    string public constant symbol = "ACE";
    uint8 public constant decimals = 18;
    uint256 public constant TOTAL_SUPPLY = 10_000_000 * 10**18;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public owner;
    bool public ownershipRenounced = false;
    bool public paused = false;

    // 黑洞地址（销毁）
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // 手续费
    uint256 public constant SELL_FEE = 200;          // 2% = 200/10000
    uint256 public constant BURN_FEE = 150;          // 1.5% = 150/10000
    uint256 public constant CHARITY_FEE = 50;        // 0.5% = 50/10000
    uint256 public constant FEE_DENOMINATOR = 10000;

    // 公益基金地址
    address public charityWallet;

    // 白名单（免手续费）
    mapping(address => bool) public isExemptFromFee;

    // 已销毁总量
    uint256 public totalBurned;

    // 事件
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Burn(address indexed burner, uint256 value);
    event CharityTransfer(address indexed charity, uint256 value);
    event Paused(address indexed by);
    event Unpaused(address indexed by);
    event CharityWalletUpdated(address indexed oldWallet, address indexed newWallet);

    modifier onlyOwner() {
        require(!ownershipRenounced && msg.sender == owner, "ACE: not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "ACE: paused");
        _;
    }

    constructor(address _charityWallet, address _owner) {
        require(_charityWallet != address(0), "ACE: charity zero address");
        require(_owner != address(0), "ACE: owner zero address");
        
        owner = _owner;
        charityWallet = _charityWallet;
        _totalSupply = TOTAL_SUPPLY;
        _balances[_owner] = TOTAL_SUPPLY;
        
        // 白名单：owner和公益基金免手续费
        isExemptFromFee[_owner] = true;
        isExemptFromFee[_charityWallet] = true;
        isExemptFromFee[BURN_ADDRESS] = true;

        emit Transfer(address(0), _owner, TOTAL_SUPPLY);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external override whenNotPaused returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address ownerAddr, address spender) external view override returns (uint256) {
        return _allowances[ownerAddr][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ACE: insufficient allowance");
        
        _transfer(from, to, amount);
        
        unchecked {
            _allowances[from][msg.sender] = currentAllowance - amount;
        }
        emit Approval(from, msg.sender, _allowances[from][msg.sender]);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0) && to != address(0), "ACE: zero address");
        require(_balances[from] >= amount && amount > 0, "ACE: invalid transfer");
        require(!paused || isExemptFromFee[from], "ACE: paused");

        // 检查是否是卖出操作（转到DEX交易对）
        bool isSell = _isSell(to);
        
        if (isSell && !isExemptFromFee[from] && !isExemptFromFee[to]) {
            // 扣2%手续费
            uint256 feeAmount = (amount * SELL_FEE) / FEE_DENOMINATOR;
            uint256 burnAmount = (amount * BURN_FEE) / FEE_DENOMINATOR;
            uint256 charityAmount = feeAmount - burnAmount;

            // 扣减余额
            _balances[from] -= amount;
            
            // 销毁部分
            _balances[BURN_ADDRESS] += burnAmount;
            totalBurned += burnAmount;
            emit Transfer(from, BURN_ADDRESS, burnAmount);
            emit Burn(from, burnAmount);

            // 公益基金部分
            _balances[charityWallet] += charityAmount;
            emit Transfer(from, charityWallet, charityAmount);
            emit CharityTransfer(charityWallet, charityAmount);

            // 接收方得到剩余
            uint256 sendAmount = amount - feeAmount;
            _balances[to] += sendAmount;
            emit Transfer(from, to, sendAmount);
        } else {
            // 免手续费转账
            _balances[from] -= amount;
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        }
    }

    // 判断是否是卖出操作（转到DEX pair）
    function _isSell(address to) internal view returns (bool) {
        // 检查接收方是否在白名单中标记为DEX pair
        // 在实际部署时，会把PancakeSwap的pair地址加入标记
        return dexPairs[to];
    }

    // DEX pair标记
    mapping(address => bool) public dexPairs;

    // ============ 管理函数 ============

    function setDexPair(address pair, bool isPair) external onlyOwner {
        dexPairs[pair] = isPair;
    }

    function setExemptFromFee(address account, bool exempt) external onlyOwner {
        isExemptFromFee[account] = exempt;
    }

    function setCharityWallet(address _charityWallet) external onlyOwner {
        require(_charityWallet != address(0), "ACE: zero address");
        address old = charityWallet;
        charityWallet = _charityWallet;
        isExemptFromFee[_charityWallet] = true;
        emit CharityWalletUpdated(old, _charityWallet);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function renounceOwnership() external onlyOwner {
        ownershipRenounced = true;
        emit OwnershipRenounced(msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ACE: zero address");
        require(!ownershipRenounced, "ACE: renounced");
        owner = newOwner;
        isExemptFromFee[newOwner] = true;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    // 紧急情况下回收非ACE代币
    function rescueToken(address token, uint256 amount) external onlyOwner {
        require(token != address(this), "ACE: cannot rescue ACE");
        require(IERC20(token).transfer(msg.sender, amount),"ACE: rescue failed");
    }
}
