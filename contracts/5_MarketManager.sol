// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ACE Market Manager
 * @dev 阿奇学院做市管理合约
 * 
 * 功能：
 * 1. 自动回购护盘（币价跌5%触发）
 * 2. 自动释放压价（币价涨10%触发）
 * 3. 护盘基金管理（基准5000U，超出转运营，低于补充）
 * 4. 每月10%回购销毁
 * 5. 质押生息（30天5%/90天10%/180天15%年化）
 */

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalBurned() external view returns (uint256);
}

interface IACEToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IDEX {
    function getPrice() external view returns (uint256);
    function buyWithUSDT(uint256 usdtAmount) external returns (uint256);
    function sellForUSDT(uint256 tokenAmount) external returns (uint256);
}

contract ACEMarketManager {
    IACEToken public immutable aceToken;
    IERC20 public immutable usdtToken;
    address public owner;
    bool public ownershipRenounced = false;
    bool public active = false;

    address public dexAddress;          // DEX路由或Pair地址
    address public platformWallet;      // 平台运营钱包
    address public charityWallet;       // 公益基金
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // 护盘基金
    uint256 public protectionFund;      // 当前护盘基金余额
    uint256 public constant PROTECTION_BASE = 5000 * 10**18;  // 基准5000U
    uint256 public constant PROTECTION_FUND_RATE = 2000;       // 运营费20%进护盘基金
    uint256 public constant PROTECTION_FUND_DENOM = 10000;

    // 触发阈值
    uint256 public dropThreshold = 500;   // 跌5%触发（初期3%）
    uint256 public riseThreshold = 1000;  // 涨10%触发（初期5%）
    uint256 public constant THRESHOLD_DENOM = 10000;

    // 回购参数
    uint256 public maxBuyPerTrigger = 1000 * 10**18;  // 每次最多用1000U
    uint256 public maxTriggersPerDay = 2;              // 每天最多2次
    uint256 public lastTriggerTime;
    uint256 public triggerCountToday;

    // 价格记录
    uint256 public price24hAgo;
    uint256 public lastPriceCheck;

    // 月度回购
    uint256 public monthlyBuybackRate = 1000;  // 运营费10%
    uint256 public lastMonthlyBuyback;

    // 质押
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 duration;     // 30/90/180天
        uint256 apr;          // 500/1000/1500 (5%/10%/15%)
        bool withdrawn;
    }
    mapping(address => Stake[]) public stakes;

    // 持有量权益等级
    uint256[4] public holdingTiers = [1000 * 10**18, 5000 * 10**18, 10000 * 10**18, 50000 * 10**18];

    // 事件
    event ProtectionBuyback(uint256 usdtSpent, uint256 aceBought, uint256 aceBurned);
    event PriceSuppress(uint256 aceSold, uint256 usdtReceived);
    event MonthlyBuyback(uint256 usdtSpent, uint256 aceBought, uint256 aceBurned);
    event ProtectionFundTopped(address indexed by, uint256 amount);
    event ProtectionFundWithdrawn(address indexed to, uint256 amount);
    event Staked(address indexed user, uint256 amount, uint256 duration, uint256 apr);
    event StakeWithdrawn(address indexed user, uint256 amount, uint256 reward);

    modifier onlyOwner() {
        require(!ownershipRenounced && msg.sender == owner, "Market: not owner");
        _;
    }

    constructor(
        address _aceToken,
        address _usdt,
        address _platformWallet,
        address _charityWallet
    ) {
        require(_aceToken != address(0) && _usdt != address(0), "Market: zero address");
        aceToken = IACEToken(_aceToken);
        usdtToken = IERC20(_usdt);
        platformWallet = _platformWallet;
        charityWallet = _charityWallet;
        owner = msg.sender;
    }

    // ============ 自动做市检查 ============
    function checkMarket() external {
        if (!active) return;

        uint256 currentPrice = _getCurrentPrice();
        if (currentPrice == 0) return;

        // 更新24小时价格
        if (block.timestamp - lastPriceCheck >= 1 days) {
            price24hAgo = currentPrice;
            lastPriceCheck = block.timestamp;
            triggerCountToday = 0;
        }

        // 检查跌幅
        if (price24hAgo > 0) {
            uint256 dropRate = ((price24hAgo - currentPrice) * THRESHOLD_DENOM) / price24hAgo;
            if (dropRate >= dropThreshold && triggerCountToday < maxTriggersPerDay) {
                _doBuyback();
                triggerCountToday++;
                lastTriggerTime = block.timestamp;
            }

            // 检查涨幅
            uint256 riseRate = ((currentPrice - price24hAgo) * THRESHOLD_DENOM) / price24hAgo;
            if (riseRate >= riseThreshold && triggerCountToday < maxTriggersPerDay) {
                _doSuppress();
                triggerCountToday++;
                lastTriggerTime = block.timestamp;
            }
        }
    }

    // ============ 回购护盘 ============
    function _doBuyback() internal {
        uint256 buyAmount = protectionFund;
        if (buyAmount > maxBuyPerTrigger) buyAmount = maxBuyPerTrigger;
        if (buyAmount == 0) return;

        // 用USDT买ACE
        usdtToken.transfer(dexAddress, buyAmount);
        uint256 aceBought = IDEX(dexAddress).buyWithUSDT(buyAmount);
        
        // 买入的ACE全部销毁
        if (aceBought > 0) {
            aceToken.transfer(BURN_ADDRESS, aceBought);
        }

        protectionFund -= buyAmount;
        emit ProtectionBuyback(buyAmount, aceBought, aceBought);
    }

    // ============ 释放压价 ============
    function _doSuppress() internal {
        // 从团队锁定池释放少量ACE卖出
        // 需要有ACE余额才能卖
        uint256 aceBalance = aceToken.balanceOf(address(this));
        uint256 sellAmount = (aceBalance * 1) / 100; // 卖1%
        
        if (sellAmount == 0) return;

        aceToken.transfer(dexAddress, sellAmount);
        uint256 usdtReceived = IDEX(dexAddress).sellForUSDT(sellAmount);

        // 卖出的USDT进护盘基金
        protectionFund += usdtReceived;
        emit PriceSuppress(sellAmount, usdtReceived);
    }

    // ============ 月度回购销毁 ============
    function doMonthlyBuyback() external onlyOwner {
        if (block.timestamp - lastMonthlyBuyback < 28 days) return;

        // 用平台运营费的10%回购
        uint256 usdtBalance = usdtToken.balanceOf(platformWallet);
        uint256 buyAmount = (usdtBalance * monthlyBuybackRate) / 10000;
        
        if (buyAmount == 0) return;

        usdtToken.transferFrom(platformWallet, address(this), buyAmount);
        usdtToken.transfer(dexAddress, buyAmount);
        uint256 aceBought = IDEX(dexAddress).buyWithUSDT(buyAmount);

        if (aceBought > 0) {
            aceToken.transfer(BURN_ADDRESS, aceBought);
        }

        lastMonthlyBuyback = block.timestamp;
        emit MonthlyBuyback(buyAmount, aceBought, aceBought);
    }

    // ============ 护盘基金管理 ============
    function topUpProtectionFund(uint256 amount) external onlyOwner {
        require(usdtToken.transferFrom(msg.sender, address(this), amount), "Market: transfer failed");
        protectionFund += amount;
        emit ProtectionFundTopped(msg.sender, amount);
    }

    function withdrawExcessProtection() external onlyOwner {
        if (protectionFund > PROTECTION_BASE) {
            uint256 excess = protectionFund - PROTECTION_BASE;
            protectionFund = PROTECTION_BASE;
            usdtToken.transfer(platformWallet, excess);
            emit ProtectionFundWithdrawn(platformWallet, excess);
        }
    }

    // ============ 质押生息 ============
    function stake(uint256 amount, uint256 durationDays) external {
        require(amount > 0, "Market: zero amount");
        require(durationDays == 30 || durationDays == 90 || durationDays == 180, "Market: invalid duration");

        uint256 apr;
        if (durationDays == 30) apr = 500;      // 5%
        else if (durationDays == 90) apr = 1000; // 10%
        else apr = 1500;                          // 15%

        require(aceToken.transferFrom(msg.sender, address(this), amount), "Market: transfer failed");

        stakes[msg.sender].push(Stake({
            amount: amount,
            startTime: block.timestamp,
            duration: durationDays * 1 days,
            apr: apr,
            withdrawn: false
        }));

        emit Staked(msg.sender, amount, durationDays, apr);
    }

    function withdrawStake(uint256 stakeIndex) external {
        Stake storage s = stakes[msg.sender][stakeIndex];
        require(!s.withdrawn, "Market: already withdrawn");
        require(block.timestamp >= s.startTime + s.duration, "Market: not matured");

        s.withdrawn = true;
        
        // 计算利息
        uint256 reward = (s.amount * s.apr * s.duration) / (10000 * 365 days);
        uint256 totalReturn = s.amount + reward;

        require(aceToken.transfer(msg.sender, totalReturn), "Market: transfer failed");

        emit StakeWithdrawn(msg.sender, s.amount, reward);
    }

    // ============ 持有量权益查询 ============
    function getHoldingTier(address user) external view returns (uint8) {
        uint256 balance = aceToken.balanceOf(user);
        uint8 tier = 0;
        for (uint8 i = 0; i < 4; i++) {
            if (balance >= holdingTiers[i]) tier = i + 1;
        }
        return tier;
    }

    // ============ 辅助 ============
    function _getCurrentPrice() internal view returns (uint256) {
        if (dexAddress == address(0)) return 0;
        try IDEX(dexAddress).getPrice() returns (uint256 price) {
            return price;
        } catch {
            return 0;
        }
    }

    // ============ 管理 ============
    function setActive(bool _active) external onlyOwner {
        active = _active;
        if (_active && lastPriceCheck == 0) {
            lastPriceCheck = block.timestamp;
            lastMonthlyBuyback = block.timestamp;
        }
    }

    function setDexAddress(address _dex) external onlyOwner {
        dexAddress = _dex;
    }

    function setThresholds(uint256 _drop, uint256 _rise) external onlyOwner {
        require(_drop >= 300 && _drop <= 1000, "Market: invalid drop");
        require(_rise >= 500 && _rise <= 2000, "Market: invalid rise");
        dropThreshold = _drop;
        riseThreshold = _rise;
    }

    function setPlatformWallet(address _w) external onlyOwner {
        platformWallet = _w;
    }

    function setCharityWallet(address _w) external onlyOwner {
        charityWallet = _w;
    }

    function depositACEForSuppress(uint256 amount) external onlyOwner {
        require(aceToken.transferFrom(msg.sender, address(this), amount), "Market: transfer failed");
    }

    function renounceOwnership() external onlyOwner {
        ownershipRenounced = true;
    }

    // ============ 查询 ============
    function getMarketStats() external view returns (
        uint256 fund, uint256 base, uint256 price, 
        uint256 triggersToday, uint256 lastTrigger
    ) {
        return (protectionFund, PROTECTION_BASE, _getCurrentPrice(), triggerCountToday, lastTriggerTime);
    }

    function getStakeInfo(address user, uint256 index) external view returns (
        uint256 amount, uint256 startTime, uint256 duration, uint256 apr, bool withdrawn, uint256 reward
    ) {
        Stake storage s = stakes[user][index];
        uint256 r = (s.amount * s.apr * s.duration) / (10000 * 365 days);
        return (s.amount, s.startTime, s.duration, s.apr, s.withdrawn, r);
    }

    function getStakeCount(address user) external view returns (uint256) {
        return stakes[user].length;
    }
}
