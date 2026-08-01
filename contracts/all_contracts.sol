// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

interface IACEToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function setDexPair(address pair, bool isPair) external;
    function setExemptFromFee(address account, bool exempt) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IReferral {
    function referrer(address) external view returns (address);
    function isPromoter(address) external view returns (bool);
    function getTeamLevel(address) external view returns (uint8);
    function updateTeamStats(address user, uint256 usdValue) external;
}

interface ILock {
    function depositStudent(address user, uint256 amount) external;
    function depositPromoter(address user, uint256 amount) external;
    function releaseStudent(address user, uint8 stage) external;
    function releasePromoterMonthly(address user) external;
    function releasePromoterByLevel(address user, uint8 newLevel) external;
    function releaseAllOnRefund(address user) external;
}

interface IDEX {
    function getPrice() external view returns (uint256);
    function buyWithUSDT(uint256 usdtAmount) external returns (uint256);
    function sellForUSDT(uint256 tokenAmount) external returns (uint256);
}


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

    constructor(address _charityWallet) {
        require(_charityWallet != address(0), "ACE: charity zero address");
        
        owner = msg.sender;
        charityWallet = _charityWallet;
        _totalSupply = TOTAL_SUPPLY;
        _balances[msg.sender] = TOTAL_SUPPLY;
        
        // 白名单：owner和公益基金免手续费
        isExemptFromFee[msg.sender] = true;
        isExemptFromFee[_charityWallet] = true;
        isExemptFromFee[BURN_ADDRESS] = true;

        emit Transfer(address(0), msg.sender, TOTAL_SUPPLY);
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

    // 紧急情况下回收非ACE代币
    function rescueToken(address token, uint256 amount) external onlyOwner {
        require(token != address(this), "ACE: cannot rescue ACE");
        IERC20(token).transfer(msg.sender, amount);
    }
}


/**
 * @title ACE Course Purchase Contract
 * @dev 阿奇学院课程购买合约
 * 
 * 功能：
 * 1. 用户用USDT买课 → 自动发ACE代币 → 注入底池 → 分润
 * 2. 推广者交1000U → 发ACE代币(锁定) → 注入底池
 * 3. 学员代币分阶段释放(30%+30%+40%)
 * 4. 推广者代币按月/级别释放
 * 5. 退课 → 释放全部剩余代币
 * 6. 公益基金1%自动扣除
 */





contract ACECourse {
    IACEToken public immutable aceToken;
    IERC20 public immutable usdtToken;
    IReferral public referralContract;
    ILock public lockContract;
    
    address public owner;
    bool public ownershipRenounced = false;
    bool public paused = false;

    // 钱包
    address public platformWallet;      // 平台运营
    address public charityWallet;       // 公益基金
    address public poolWallet;          // 底池注入（临时存放，定期加底池）

    // 价格
    uint256 public acePrice;            // ACE价格（精度1e18，1 ACE = acePrice/1e18 USDT）
    uint256 public lastPriceUpdate;

    // 统计
    uint256 public totalStudents;       // 总学员数
    uint256 public totalPromoters;      // 总推广者数
    uint256 public totalRevenue;        // 总收入
    uint256 public totalCharity;        // 公益基金总额

    // 课程
    struct Course {
        uint256 price;      // USDT价格
        bool active;        // 是否上架
    }
    mapping(uint256 => Course) public courses;
    uint256 public courseCount;

    // 学员记录
    struct StudentRecord {
        uint256 totalPaid;          // 总付费USDT
        uint256 aceAllocated;       // 分配的ACE总量
        uint256 aceReleased;        // 已释放的ACE
        uint8 coursesCompleted;     // 完成课程数
        bool examPassed;            // 考试是否通过
        bool refunded;              // 是否已退课
    }
    mapping(address => StudentRecord) public students;
    address[] public allStudents;

    // 推广者记录
    struct PromoterRecord {
        uint256 paidAmount;         // 交的USDT
        uint256 aceAllocated;       // 分配的ACE总量
        uint256 aceReleased;        // 已释放的ACE
        uint8 lastReleaseMonth;     // 上次释放的月份
        uint8 teamLevel;            // 上次释放时的级别
        bool active;
    }
    mapping(address => PromoterRecord) public promoters;

    // 分配比例
    uint256 public constant DIRECT_RATE_MAX = 2800;    // 最高28%
    uint256 public constant POOL_RATE = 2000;           // 20%底池
    uint256 public constant STUDENT_ACE_RATE = 2000;    // 20%等值代币
    uint256 public constant TEAM_REWARD_RATE = 400;     // 4%团队奖励
    uint256 public constant CHARITY_RATE = 100;         // 1%公益基金
    uint256 public constant RATE_DENOM = 10000;

    // 推广者费用
    uint256 public promoterFee = 1000 * 10**18;  // 初始1000U
    uint256 public promoterCount = 0;
    
    // 推广者分阶段定价
    uint256[] public promoterTiers;  // [100, 300, 600] 人数门槛
    uint256[] public promoterPrices; // [1000U, 2000U, 5000U, 10000U]

    // 事件
    event CoursePurchased(address indexed student, uint256 courseId, uint256 price, uint256 aceAmount);
    event PromoterRegistered(address indexed promoter, uint256 paidAmount, uint256 aceAmount);
    event StudentACEReleased(address indexed student, uint8 stage, uint256 amount);
    event PromoterACEReleased(address indexed promoter, uint256 amount, string releaseType);
    event CourseRefunded(address indexed student, uint256 aceReleased);
    event CharityDeposited(uint256 amount);
    event CourseAdded(uint256 indexed courseId, uint256 price);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);

    modifier onlyOwner() {
        require(!ownershipRenounced && msg.sender == owner, "Course: not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Course: paused");
        _;
    }

    constructor(
        address _aceToken,
        address _usdt,
        address _platformWallet,
        address _charityWallet,
        address _poolWallet
    ) {
        require(_aceToken != address(0) && _usdt != address(0), "Course: zero address");
        aceToken = IACEToken(_aceToken);
        usdtToken = IERC20(_usdt);
        platformWallet = _platformWallet;
        charityWallet = _charityWallet;
        poolWallet = _poolWallet;
        owner = msg.sender;
        acePrice = 1 * 10**16; // 0.01 USDT per ACE (精度1e18)
        lastPriceUpdate = block.timestamp;

        // 推广者分阶段定价
        promoterTiers = [100, 300, 600];
        promoterPrices = [1000 * 10**18, 2000 * 10**18, 5000 * 10**18, 10000 * 10**18];
    }

    // ============ 买课程 ============
    function buyCourse(uint256 courseId) external whenNotPaused {
        require(courses[courseId].active, "Course: not active");
        uint256 price = courses[courseId].price;
        require(price > 0, "Course: invalid price");

        // 检查推荐人
        address ref = referralContract.referrer(msg.sender);
        require(ref != address(0), "Course: need referrer");

        // 收USDT
        require(usdtToken.transferFrom(msg.sender, address(this), price), "Course: USDT failed");

        // 计算ACE数量
        uint256 aceAmount = (price * 1e18) / acePrice;

        // 分配USDT
        _distributeFunds(price, msg.sender, ref);

        // 分配ACE代币（锁定）
        if (aceAmount > 0) {
            require(aceToken.transfer(address(lockContract), aceAmount), "Course: ACE transfer failed");
            lockContract.depositStudent(msg.sender, aceAmount);
        }

        // 记录学员
        StudentRecord storage s = students[msg.sender];
        if (s.totalPaid == 0) {
            allStudents.push(msg.sender);
            totalStudents++;
        }
        s.totalPaid += price;
        s.aceAllocated += aceAmount;

        // 释放第一阶段30%
        uint256 releaseAmount = (aceAmount * 30) / 100;
        lockContract.releaseStudent(msg.sender, 0);
        s.aceReleased += releaseAmount;

        // 更新团队业绩
        if (address(referralContract) != address(0)) {
            referralContract.updateTeamStats(msg.sender, price);
        }

        totalRevenue += price;
        emit CoursePurchased(msg.sender, courseId, price, aceAmount);
        emit StudentACEReleased(msg.sender, 0, releaseAmount);
    }

    // ============ 推广者注册 ============
    function registerPromoter() external whenNotPaused {
        // 检查推荐人
        address ref = referralContract.referrer(msg.sender);
        require(ref != address(0), "Course: need referrer");
        require(!promoters[msg.sender].active, "Course: already promoter");

        // 获取当前价格
        uint256 fee = getCurrentPromoterPrice();
        require(usdtToken.transferFrom(msg.sender, address(this), fee), "Course: USDT failed");

        // 分配USDT
        // 59%平台 + 20%底池 + 20%代币 + 1%公益
        uint256 platformAmount = (fee * 5900) / RATE_DENOM;
        uint256 poolAmount = (fee * 2000) / RATE_DENOM;
        uint256 charityAmount = (fee * 100) / RATE_DENOM;
        uint256 aceUsdValue = fee - platformAmount - poolAmount - charityAmount;

        usdtToken.transfer(platformWallet, platformAmount);
        usdtToken.transfer(poolWallet, poolAmount);
        usdtToken.transfer(charityWallet, charityAmount);
        totalCharity += charityAmount;
        emit CharityDeposited(charityAmount);

        // 推广者的推荐人拿直推
        if (ref != address(0)) {
            uint8 refLevel = referralContract.getTeamLevel(ref);
            bool refIsPromoter = referralContract.isPromoter(ref);
            uint256 directRate = _getDirectRate(refLevel, refIsPromoter);
            uint256 directAmount = (fee * directRate) / RATE_DENOM;
            if (directAmount > 0 && directAmount <= platformAmount) {
                usdtToken.transfer(ref, directAmount);
            }
        }

        // 计算ACE数量
        uint256 aceAmount = (aceUsdValue * 1e18) / acePrice;

        // 分配ACE代币（锁定）
        if (aceAmount > 0) {
            require(aceToken.transfer(address(lockContract), aceAmount), "Course: ACE transfer failed");
            lockContract.depositPromoter(msg.sender, aceAmount);
        }

        // 记录推广者
        promoters[msg.sender] = PromoterRecord({
            paidAmount: fee,
            aceAllocated: aceAmount,
            aceReleased: 0,
            lastReleaseMonth: _getCurrentMonth(),
            teamLevel: 0,
            active: true
        });
        totalPromoters++;
        promoterCount++;

        totalRevenue += fee;
        emit PromoterRegistered(msg.sender, fee, aceAmount);
    }

    // ============ 学员代币释放 ============
    function releaseStudentStage2(address student) external whenNotPaused {
        StudentRecord storage s = students[student];
        require(s.aceAllocated > 0, "Course: no allocation");
        require(s.coursesCompleted >= 1, "Course: need complete 1 course");
        require(s.aceReleased < s.aceAllocated, "Course: all released");

        lockContract.releaseStudent(student, 1);
        uint256 releaseAmount = (s.aceAllocated * 30) / 100;
        s.aceReleased += releaseAmount;
        emit StudentACEReleased(student, 1, releaseAmount);
    }

    function releaseStudentStage3(address student) external whenNotPaused {
        StudentRecord storage s = students[student];
        require(s.aceAllocated > 0, "Course: no allocation");
        require(s.examPassed, "Course: need exam passed");
        require(s.aceReleased < s.aceAllocated, "Course: all released");

        lockContract.releaseStudent(student, 2);
        uint256 releaseAmount = (s.aceAllocated * 40) / 100;
        s.aceReleased += releaseAmount;
        emit StudentACEReleased(student, 2, releaseAmount);
    }

    // ============ 推广者代币释放 ============
    function releasePromoterMonthly(address promoter) external whenNotPaused {
        PromoterRecord storage p = promoters[promoter];
        require(p.active, "Course: not active");
        require(p.aceReleased < p.aceAllocated, "Course: all released");
        
        uint8 currentMonth = _getCurrentMonth();
        require(currentMonth > p.lastReleaseMonth, "Course: already released this month");

        lockContract.releasePromoterMonthly(promoter);
        uint256 releaseAmount = (p.aceAllocated * 10) / 100;
        p.aceReleased += releaseAmount;
        p.lastReleaseMonth = currentMonth;
        emit PromoterACEReleased(promoter, releaseAmount, "monthly");
    }

    function releasePromoterByLevel(address promoter, uint8 newLevel) external whenNotPaused {
        PromoterRecord storage p = promoters[promoter];
        require(p.active, "Course: not active");
        require(newLevel > p.teamLevel, "Course: level not increased");

        lockContract.releasePromoterByLevel(promoter, newLevel);
        uint256 releaseAmount = (p.aceAllocated * 10) / 100;
        p.aceReleased += releaseAmount;
        p.teamLevel = newLevel;
        emit PromoterACEReleased(promoter, releaseAmount, "level");
    }

    // ============ 退课 ============
    function refundCourse(address student) external whenNotPaused {
        StudentRecord storage s = students[student];
        require(s.aceAllocated > 0, "Course: no allocation");
        require(!s.refunded, "Course: already refunded");
        require(!s.examPassed, "Course: exam passed, no refund");

        // 释放全部剩余代币
        uint256 remaining = s.aceAllocated - s.aceReleased;
        if (remaining > 0) {
            lockContract.releaseAllOnRefund(student);
            s.aceReleased = s.aceAllocated;
        }

        s.refunded = true;
        emit CourseRefunded(student, remaining);
    }

    // ============ 资金分配 ============
    function _distributeFunds(uint256 amount, address student, address ref) internal {
        // 直推奖
        uint8 refLevel = referralContract.getTeamLevel(ref);
        bool refIsPromoter = referralContract.isPromoter(ref);
        uint256 directRate = _getDirectRate(refLevel, refIsPromoter);
        uint256 directAmount = (amount * directRate) / RATE_DENOM;

        // 底池
        uint256 poolAmount = (amount * POOL_RATE) / RATE_DENOM;

        // 学员ACE等值
        uint256 aceUsdValue = (amount * STUDENT_ACE_RATE) / RATE_DENOM;

        // 团队奖励
        uint256 teamReward = (amount * TEAM_REWARD_RATE) / RATE_DENOM;

        // 公益基金
        uint256 charityAmount = (amount * CHARITY_RATE) / RATE_DENOM;

        // 平台运营 = 剩余
        uint256 platformAmount = amount - directAmount - poolAmount - aceUsdValue - teamReward - charityAmount;

        // 转账
        if (directAmount > 0) usdtToken.transfer(ref, directAmount);
        usdtToken.transfer(poolWallet, poolAmount);
        usdtToken.transfer(charityWallet, charityAmount);
        // teamReward留在合约，由推广奖励合约提取
        // platformAmount转给平台
        usdtToken.transfer(platformWallet, platformAmount);

        totalCharity += charityAmount;
        emit CharityDeposited(charityAmount);
    }

    // ============ 直推比例 ============
    function _getDirectRate(uint8 level, bool isPromoter) internal pure returns (uint256) {
        // 学员：15%, 17%, 19%, 21%, 23%
        // 推广者：20%, 22%, 24%, 26%, 28%
        uint256[5] memory studentRates = [uint256(1500), uint256(1700), uint256(1900), uint256(2100), uint256(2300)];
        uint256[5] memory promoterRates = [uint256(2000), uint256(2200), uint256(2400), uint256(2600), uint256(2800)];
        
        if (level > 4) level = 4;
        return isPromoter ? promoterRates[level] : studentRates[level];
    }

    // ============ 推广者价格 ============
    function getCurrentPromoterPrice() public view returns (uint256) {
        for (uint256 i = 0; i < promoterTiers.length; i++) {
            if (promoterCount < promoterTiers[i]) {
                return promoterPrices[i];
            }
        }
        return promoterPrices[promoterPrices.length - 1];
    }

    // ============ 辅助 ============
    function _getCurrentMonth() internal view returns (uint8) {
        return uint8((block.timestamp / 30 days) % 12 + 1);
    }

    // ============ 管理函数 ============
    function addCourse(uint256 price) external onlyOwner {
        courseCount++;
        courses[courseCount] = Course(price, true);
        emit CourseAdded(courseCount, price);
    }

    function setCourseActive(uint256 courseId, bool active) external onlyOwner {
        courses[courseId].active = active;
    }

    function updatePrice(uint256 newPrice) external onlyOwner {
        uint256 old = acePrice;
        acePrice = newPrice;
        lastPriceUpdate = block.timestamp;
        emit PriceUpdated(old, newPrice);
    }

    function setReferralContract(address _ref) external onlyOwner {
        referralContract = IReferral(_ref);
    }

    function setLockContract(address _lock) external onlyOwner {
        lockContract = ILock(_lock);
    }

    function setPlatformWallet(address _w) external onlyOwner {
        platformWallet = _w;
    }

    function setCharityWallet(address _w) external onlyOwner {
        charityWallet = _w;
    }

    function setPoolWallet(address _w) external onlyOwner {
        poolWallet = _w;
    }

    function markCourseCompleted(address student) external onlyOwner {
        students[student].coursesCompleted++;
    }

    function markExamPassed(address student) external onlyOwner {
        students[student].examPassed = true;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function renounceOwnership() external onlyOwner {
        ownershipRenounced = true;
    }

    function rescueToken(address token, uint256 amount) external onlyOwner {
        require(token != address(aceToken), "Course: cannot rescue ACE");
        IERC20(token).transfer(msg.sender, amount);
    }

    // ============ 查询 ============
    function getStudentInfo(address student) external view returns (
        uint256 totalPaid, uint256 aceAllocated, uint256 aceReleased,
        uint8 coursesCompleted, bool examPassed, bool refunded
    ) {
        StudentRecord storage s = students[student];
        return (s.totalPaid, s.aceAllocated, s.aceReleased, s.coursesCompleted, s.examPassed, s.refunded);
    }

    function getPromoterInfo(address promoter) external view returns (
        uint256 paidAmount, uint256 aceAllocated, uint256 aceReleased,
        uint8 lastReleaseMonth, uint8 teamLevel, bool active
    ) {
        PromoterRecord storage p = promoters[promoter];
        return (p.paidAmount, p.aceAllocated, p.aceReleased, p.lastReleaseMonth, p.teamLevel, p.active);
    }

    function getStats() external view returns (
        uint256 _totalStudents, uint256 _totalPromoters,
        uint256 _totalRevenue, uint256 _totalCharity,
        uint256 _acePrice, uint256 _promoterPrice
    ) {
        return (totalStudents, totalPromoters, totalRevenue, totalCharity, acePrice, getCurrentPromoterPrice());
    }
}


/**
 * @title ACE Referral & Rewards Contract
 * @dev 阿奇学院推广奖励合约
 * 
 * 功能：
 * 1. 推荐关系绑定（必须有推荐人）
 * 2. 团队级别管理（5级：学长→辅导员→班主任→导师→校长，只升不降）
 * 3. 推广者身份管理（交1000U成为推广者，永远比学员高5%）
 * 4. 团队业绩统计
 * 5. 合伙人管理（最多50人，第二阶段启用）
 */


interface ICourse {
    function updatePrice(uint256 newPrice) external;
}

contract ACEReferral {
    IERC20 public immutable aceToken;
    address public owner;
    bool public ownershipRenounced = false;

    address public courseContract;

    // 推荐关系
    mapping(address => address) public referrer;
    mapping(address => address[]) public directReferrals;
    
    // 团队业绩
    mapping(address => uint256) public teamTotalUSD;     // 团队总业绩
    mapping(address => uint256) public teamTotalCount;   // 团队总人数
    mapping(address => uint256) public personalUSD;      // 个人业绩

    // 推广者身份
    mapping(address => bool) public isPromoter;
    
    // 团队级别 0=学长 1=辅导员 2=班主任 3=导师 4=校长
    mapping(address => uint8) public teamLevel;

    // 合伙人
    mapping(address => bool) public isPartner;
    uint256 public partnerCount;
    uint256 public constant MAX_PARTNERS = 50;

    // 级别条件
    struct LevelCondition {
        uint256 minTeamCount;
        uint256 minTeamUSD;
    }
    LevelCondition[] public levelConditions;

    // 团队代币奖励（每新增1000U业绩奖多少币）
    uint256[] public levelTokenRewards; // [0, 500, 800, 1200, 2000]

    // 事件
    event ReferralRegistered(address indexed user, address indexed referrer);
    event PromoterStatusChanged(address indexed user, bool isPromoter);
    event TeamLevelUp(address indexed user, uint8 oldLevel, uint8 newLevel);
    event PartnerAdded(address indexed partner);
    event TeamRewardSent(address indexed upline, uint256 amount);

    modifier onlyOwner() {
        require(!ownershipRenounced && msg.sender == owner, "Referral: not owner");
        _;
    }

    modifier onlyCourseContract() {
        require(msg.sender == courseContract || msg.sender == owner, "Referral: only course");
        _;
    }

    constructor(address _aceToken) {
        require(_aceToken != address(0), "Referral: zero address");
        aceToken = IERC20(_aceToken);
        owner = msg.sender;

        // 级别条件
        // 0=学长: 推荐3人
        // 1=辅导员: 团队20人 + 5000U
        // 2=班主任: 团队100人 + 30000U
        // 3=导师: 团队500人 + 150000U
        // 4=校长: 团队2000人 + 500000U
        levelConditions.push(LevelCondition(3, 0));
        levelConditions.push(LevelCondition(20, 5000 * 10**18));
        levelConditions.push(LevelCondition(100, 30000 * 10**18));
        levelConditions.push(LevelCondition(500, 150000 * 10**18));
        levelConditions.push(LevelCondition(2000, 500000 * 10**18));

        // 每新增1000U业绩奖多少ACE币
        levelTokenRewards = [0, 500 * 10**18, 800 * 10**18, 1200 * 10**18, 2000 * 10**18];
    }

    // ============ 绑定推荐关系 ============
    function registerReferral(address user, address _referrer) external {
        require(msg.sender == user || msg.sender == courseContract || msg.sender == owner, "Referral: not authorized");
        require(_referrer != address(0) && _referrer != user, "Referral: invalid referrer");
        require(referrer[user] == address(0), "Referral: already has referrer");

        referrer[user] = _referrer;
        directReferrals[_referrer].push(user);

        // 更新上级团队人数
        address up = _referrer;
        while (up != address(0)) {
            teamTotalCount[up]++;
            up = referrer[up];
        }

        emit ReferralRegistered(user, _referrer);
    }

    // ============ 更新团队业绩 ============
    function updateTeamStats(address user, uint256 usdValue) external onlyCourseContract {
        personalUSD[user] += usdValue;
        
        address up = referrer[user];
        uint256 oldLevel = teamLevel[up];
        
        while (up != address(0)) {
            teamTotalUSD[up] += usdValue;
            
            // 检查升级
            uint8 newLevel = _checkLevel(up);
            if (newLevel > teamLevel[up]) {
                uint8 old = teamLevel[up];
                teamLevel[up] = newLevel;
                emit TeamLevelUp(up, old, newLevel);

                // 发团队代币奖励
                _sendTeamReward(up, usdValue, newLevel);
            } else if (teamLevel[up] > 0) {
                // 已有级别，按当前级别发奖励
                _sendTeamReward(up, usdValue, teamLevel[up]);
            }

            up = referrer[up];
        }
    }

    // ============ 团队代币奖励 ============
    function _sendTeamReward(address upline, uint256 newUSD, uint8 level) internal {
        if (level == 0) return; // 学长无奖励
        
        // 每新增1000U业绩奖多少币
        uint256 reward = (newUSD * levelTokenRewards[level]) / (1000 * 10**18);
        if (reward > 0 && aceToken.balanceOf(address(this)) >= reward) {
            aceToken.transfer(upline, reward);
            emit TeamRewardSent(upline, reward);
        }
    }

    // ============ 检查级别 ============
    function _checkLevel(address user) internal view returns (uint8) {
        uint256 teamCount = teamTotalCount[user];
        uint256 teamUSD = teamTotalUSD[user];
        uint8 currentLevel = teamLevel[user];

        // 只升不降，从当前级别往上检查
        for (uint8 i = currentLevel; i < levelConditions.length; i++) {
            if (i == 0) {
                // 学长：推荐3人
                if (directReferrals[user].length >= levelConditions[0].minTeamCount) {
                    if (currentLevel < 1) return 1;
                }
            } else {
                if (teamCount >= levelConditions[i].minTeamCount && teamUSD >= levelConditions[i].minTeamUSD) {
                    return uint8(i + 1 > levelConditions.length ? levelConditions.length - 1 : i + 1);
                }
            }
        }
        
        // 检查学长级别
        if (directReferrals[user].length >= 3) {
            return currentLevel < 1 ? 1 : currentLevel;
        }
        
        return currentLevel;
    }

    // ============ 设置推广者身份 ============
    function setPromoter(address user, bool _isPromoter) external onlyCourseContract {
        isPromoter[user] = _isPromoter;
        emit PromoterStatusChanged(user, _isPromoter);
    }

    // ============ 合伙人 ============
    function addPartner(address partner) external onlyOwner {
        require(partnerCount < MAX_PARTNERS, "Referral: max partners");
        require(!isPartner[partner], "Referral: already partner");
        isPartner[partner] = true;
        partnerCount++;
        // 合伙人直接是校长级别
        teamLevel[partner] = 4;
        emit PartnerAdded(partner);
    }

    // ============ 查询 ============
    function getTeamLevel(address user) external view returns (uint8) {
        return teamLevel[user];
    }

    function getDirectCount(address user) external view returns (uint256) {
        return directReferrals[user].length;
    }

    function getDirectReferrals(address user) external view returns (address[] memory) {
        return directReferrals[user];
    }

    function getTeamStats(address user) external view returns (
        uint256 personal, uint256 teamUSD, uint256 teamCount, uint8 level, bool promoter, bool partner
    ) {
        return (personalUSD[user], teamTotalUSD[user], teamTotalCount[user], teamLevel[user], isPromoter[user], isPartner[user]);
    }

    // ============ 管理函数 ============
    function setCourseContract(address _course) external onlyOwner {
        courseContract = _course;
    }

    function depositRewardTokens(uint256 amount) external onlyOwner {
        require(aceToken.transferFrom(msg.sender, address(this), amount), "Referral: transfer failed");
    }

    function renounceOwnership() external onlyOwner {
        ownershipRenounced = true;
    }

    function rescueToken(address token, uint256 amount) external onlyOwner {
        require(token != address(aceToken), "Referral: cannot rescue ACE");
        IERC20(token).transfer(msg.sender, amount);
    }
}


/**
 * @title ACE Token Lock Contract
 * @dev 阿奇学院代币锁定合约
 * 
 * 功能：
 * 1. 学员代币分阶段释放（30%+30%+40%）
 * 2. 推广者代币按月释放（每月10%）或升级加速（+10%）
 * 3. 阶梯销毁：急速10%销毁 / 标准5%销毁 / 慢速0%销毁
 * 4. 退课时一次性释放全部剩余
 */


contract ACELock {
    IERC20 public immutable aceToken;
    address public owner;
    bool public ownershipRenounced = false;

    address public courseContract;

    // 学员锁定记录
    struct StudentLock {
        uint256 totalLocked;        // 总锁定量
        uint256 released;           // 已释放量
        uint8 stagesReleased;       // 已释放的阶段数（0=报名, 1=学完第一门, 2=考试通过）
    }
    mapping(address => StudentLock) public studentLocks;

    // 推广者锁定记录
    struct PromoterLock {
        uint256 totalLocked;        // 总锁定量
        uint256 released;           // 已释放量
        uint8 lastReleaseMonth;     // 上次释放月份
        uint8 lastLevel;            // 上次释放时的级别
        uint256 baseReleased;       // 基础释放累计
        uint256 boostReleased;      // 加速释放累计
    }
    mapping(address => PromoterLock) public promoterLocks;

    // 阶梯销毁比例
    uint256 public constant FAST_BURN = 1000;   // 急速10%
    uint256 public constant STANDARD_BURN = 500; // 标准5%
    uint256 public constant SLOW_BURN = 0;       // 慢速0%
    uint256 public constant BURN_DENOM = 10000;

    // 释放比例
    uint256 public constant STAGE1 = 30;   // 报名30%
    uint256 public constant STAGE2 = 30;   // 学完第一门30%
    uint256 public constant STAGE3 = 40;   // 考试通过40%
    uint256 public constant MONTHLY = 10;  // 推广者每月10%
    uint256 public constant BOOST = 10;    // 升级加速10%

    // 黑洞地址
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // 事件
    event StudentDeposited(address indexed student, uint256 amount);
    event StudentReleased(address indexed student, uint8 stage, uint256 amount, uint256 burnAmount);
    event PromoterDeposited(address indexed promoter, uint256 amount);
    event PromoterMonthlyReleased(address indexed promoter, uint256 amount, uint256 burnAmount);
    event PromoterBoostReleased(address indexed promoter, uint256 amount, uint256 burnAmount);
    event RefundReleased(address indexed user, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    modifier onlyOwner() {
        require(!ownershipRenounced && msg.sender == owner, "Lock: not owner");
        _;
    }

    modifier onlyCourseContract() {
        require(msg.sender == courseContract, "Lock: only course");
        _;
    }

    constructor(address _aceToken) {
        require(_aceToken != address(0), "Lock: zero address");
        aceToken = IERC20(_aceToken);
        owner = msg.sender;
    }

    // ============ 学员存入 ============
    function depositStudent(address student, uint256 amount) external onlyCourseContract {
        StudentLock storage s = studentLocks[student];
        s.totalLocked += amount;
        emit StudentDeposited(student, amount);
    }

    // ============ 学员释放 ============
    function releaseStudent(address student, uint8 stage) external onlyCourseContract {
        StudentLock storage s = studentLocks[student];
        require(s.totalLocked > 0, "Lock: no lock");
        require(stage < 3, "Lock: invalid stage");

        uint256 releaseAmount;
        if (stage == 0) {
            releaseAmount = (s.totalLocked * STAGE1) / 100;
        } else if (stage == 1) {
            releaseAmount = (s.totalLocked * STAGE2) / 100;
        } else {
            releaseAmount = (s.totalLocked * STAGE3) / 100;
        }

        // 已释放的不能重复
        uint256 totalShouldRelease = ((stage + 1) == 1) ? (s.totalLocked * STAGE1) / 100 :
                                      ((stage + 1) == 2) ? (s.totalLocked * (STAGE1 + STAGE2)) / 100 :
                                      s.totalLocked;
        
        if (s.released >= totalShouldRelease) return; // 已释放

        releaseAmount = totalShouldRelease - s.released;
        s.released += releaseAmount;

        // 直接转给学员（标准释放，5%销毁）
        uint256 burnAmount = (releaseAmount * STANDARD_BURN) / BURN_DENOM;
        uint256 sendAmount = releaseAmount - burnAmount;

        if (burnAmount > 0) {
            aceToken.transfer(BURN_ADDRESS, burnAmount);
            emit Burned(student, burnAmount);
        }
        if (sendAmount > 0) {
            aceToken.transfer(student, sendAmount);
        }

        emit StudentReleased(student, stage, sendAmount, burnAmount);
    }

    // ============ 推广者存入 ============
    function depositPromoter(address promoter, uint256 amount) external onlyCourseContract {
        PromoterLock storage p = promoterLocks[promoter];
        p.totalLocked += amount;
        if (p.lastReleaseMonth == 0) {
            p.lastReleaseMonth = _getCurrentMonth();
        }
        emit PromoterDeposited(promoter, amount);
    }

    // ============ 推广者按月释放 ============
    function releasePromoterMonthly(address promoter) external onlyCourseContract {
        PromoterLock storage p = promoterLocks[promoter];
        require(p.totalLocked > 0, "Lock: no lock");
        require(p.released < p.totalLocked, "Lock: all released");

        uint8 currentMonth = _getCurrentMonth();
        require(currentMonth > p.lastReleaseMonth, "Lock: already released this month");

        uint256 releaseAmount = (p.totalLocked * MONTHLY) / 100;
        if (p.released + releaseAmount > p.totalLocked) {
            releaseAmount = p.totalLocked - p.released;
        }

        p.released += releaseAmount;
        p.baseReleased += releaseAmount;
        p.lastReleaseMonth = currentMonth;

        // 标准释放5%销毁
        uint256 burnAmount = (releaseAmount * STANDARD_BURN) / BURN_DENOM;
        uint256 sendAmount = releaseAmount - burnAmount;

        if (burnAmount > 0) {
            aceToken.transfer(BURN_ADDRESS, burnAmount);
            emit Burned(promoter, burnAmount);
        }
        if (sendAmount > 0) {
            aceToken.transfer(promoter, sendAmount);
        }

        emit PromoterMonthlyReleased(promoter, sendAmount, burnAmount);
    }

    // ============ 推广者升级加速释放 ============
    function releasePromoterByLevel(address promoter, uint8 newLevel) external onlyCourseContract {
        PromoterLock storage p = promoterLocks[promoter];
        require(p.totalLocked > 0, "Lock: no lock");
        require(newLevel > p.lastLevel, "Lock: level not increased");
        require(p.released < p.totalLocked, "Lock: all released");

        uint256 releaseAmount = (p.totalLocked * BOOST) / 100;
        if (p.released + releaseAmount > p.totalLocked) {
            releaseAmount = p.totalLocked - p.released;
        }

        p.released += releaseAmount;
        p.boostReleased += releaseAmount;
        p.lastLevel = newLevel;

        // 加速释放0%销毁（慢速）
        if (releaseAmount > 0) {
            aceToken.transfer(promoter, releaseAmount);
        }

        emit PromoterBoostReleased(promoter, releaseAmount, 0);
    }

    // ============ 退课一次性释放 ============
    function releaseAllOnRefund(address user) external onlyCourseContract {
        StudentLock storage s = studentLocks[user];
        if (s.totalLocked > 0) {
            uint256 remaining = s.totalLocked - s.released;
            s.released = s.totalLocked;

            if (remaining > 0) {
                aceToken.transfer(user, remaining);
            }

            emit RefundReleased(user, remaining);
        }
    }

    // ============ 查询 ============
    function getStudentLock(address student) external view returns (uint256 total, uint256 released, uint8 stages) {
        StudentLock storage s = studentLocks[student];
        return (s.totalLocked, s.released, s.stagesReleased);
    }

    function getPromoterLock(address promoter) external view returns (
        uint256 total, uint256 released, uint8 lastMonth, uint8 lastLevel
    ) {
        PromoterLock storage p = promoterLocks[promoter];
        return (p.totalLocked, p.released, p.lastReleaseMonth, p.lastLevel);
    }

    // ============ 辅助 ============
    function _getCurrentMonth() internal view returns (uint8) {
        return uint8((block.timestamp / 30 days) % 100);
    }

    // ============ 管理 ============
    function setCourseContract(address _course) external onlyOwner {
        courseContract = _course;
    }

    function renounceOwnership() external onlyOwner {
        ownershipRenounced = true;
    }
}


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


/**
 * @title ACE Certificate NFT
 * @dev 阿奇学院链上证书合约
 * 
 * 功能：
 * 1. 学完课程+考试通过 → 铸造NFT证书
 * 2. 证书永久不可篡改
 * 3. 铸造证书消耗少量ACE代币（增加代币使用场景）
 * 4. 链上可验证
 */


interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ACECertificate {
    // NFT基本信息
    string public constant name = "ACE Academy Certificate";
    string public constant symbol = "ACEC";
    
    IERC20 public immutable aceToken;
    address public owner;
    bool public ownershipRenounced = false;
    address public courseContract;

    // 证书铸造费用（消耗ACE代币）
    uint256 public mintCost = 50 * 10**18;  // 50 ACE

    // 黑洞地址
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // 证书数据
    struct Certificate {
        address student;            // 学员地址
        string direction;           // 学习方向
        uint256 coursesCompleted;   // 完成课程数
        uint256 examScore;          // 考试分数
        uint256 issuedAt;           // 颁发时间
        string certificateId;       // 证书编号
    }

    // NFT存储
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => Certificate) public certificates;
    mapping(uint256 => string) private _tokenURIs;
    
    uint256 private _nextTokenId = 1;
    uint256 public totalCertificates;

    // 事件
    event CertificateMinted(uint256 indexed tokenId, address indexed student, string direction, uint256 score);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    modifier onlyOwner() {
        require(!ownershipRenounced && msg.sender == owner, "Cert: not owner");
        _;
    }

    modifier onlyCourseContract() {
        require(msg.sender == courseContract || msg.sender == owner, "Cert: only course");
        _;
    }

    constructor(address _aceToken) {
        require(_aceToken != address(0), "Cert: zero address");
        aceToken = IERC20(_aceToken);
        owner = msg.sender;
    }

    // ============ 铸造证书 ============
    function mintCertificate(
        address student,
        string memory direction,
        uint256 coursesCompleted,
        uint256 examScore
    ) external onlyCourseContract returns (uint256) {
        require(examScore >= 70, "Cert: exam not passed");
        require(_balances[student] < 10, "Cert: max 10 certificates per user");

        // 消耗ACE代币（从学员扣除，销毁）
        if (mintCost > 0) {
            require(
                aceToken.transferFrom(student, BURN_ADDRESS, mintCost),
                "Cert: insufficient ACE for minting"
            );
        }

        uint256 tokenId = _nextTokenId++;
        
        // 生成证书编号
        string memory certId = _generateCertId(tokenId, student);

        certificates[tokenId] = Certificate({
            student: student,
            direction: direction,
            coursesCompleted: coursesCompleted,
            examScore: examScore,
            issuedAt: block.timestamp,
            certificateId: certId
        });

        // 铸造NFT
        _owners[tokenId] = student;
        _balances[student]++;
        totalCertificates++;

        emit CertificateMinted(tokenId, student, direction, examScore);
        emit Transfer(address(0), student, tokenId);

        return tokenId;
    }

    // ============ 生成证书编号 ============
    function _generateCertId(uint256 tokenId, address student) internal view returns (string memory) {
        return string(abi.encodePacked(
            "ACE-",
            _uintToString(block.timestamp / 1 days),
            "-",
            _uintToString(tokenId)
        ));
    }

    function _uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // ============ NFT标准接口 ============
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address tokenOwner = _owners[tokenId];
        require(tokenOwner != address(0), "Cert: invalid token ID");
        return tokenOwner;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_owners[tokenId] != address(0), "Cert: invalid token ID");
        return _tokenURIs[tokenId];
    }

    function setTokenURI(uint256 tokenId, string memory uri) external onlyOwner {
        require(_owners[tokenId] != address(0), "Cert: invalid token ID");
        _tokenURIs[tokenId] = uri;
    }

    // ============ 证书查询 ============
    function getCertificate(uint256 tokenId) external view returns (
        address student,
        string memory direction,
        uint256 coursesCompleted,
        uint256 examScore,
        uint256 issuedAt,
        string memory certificateId
    ) {
        Certificate storage cert = certificates[tokenId];
        return (cert.student, cert.direction, cert.coursesCompleted, cert.examScore, cert.issuedAt, cert.certificateId);
    }

    function getCertificatesByOwner(address student) external view returns (uint256[] memory) {
        uint256 count = _balances[student];
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= _nextTokenId - 1; i++) {
            if (_owners[i] == student) {
                result[index] = i;
                index++;
            }
        }
        return result;
    }

    function verifyCertificate(uint256 tokenId) external view returns (bool) {
        return _owners[tokenId] != address(0) && bytes(certificates[tokenId].certificateId).length > 0;
    }

    // ============ 管理 ============
    function setMintCost(uint256 cost) external onlyOwner {
        mintCost = cost;
    }

    function setCourseContract(address _course) external onlyOwner {
        courseContract = _course;
    }

    function setTokenURIBatch(uint256[] memory tokenIds, string[] memory uris) external onlyOwner {
        require(tokenIds.length == uris.length, "Cert: length mismatch");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_owners[tokenIds[i]] != address(0)) {
                _tokenURIs[tokenIds[i]] = uris[i];
            }
        }
    }

    function renounceOwnership() external onlyOwner {
        ownershipRenounced = true;
    }
}

