// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IACEToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function setDexPair(address pair, bool isPair) external;
    function setExemptFromFee(address account, bool exempt) external;
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

contract ACECourse {
    IACEToken public immutable aceToken;
    IERC20 public immutable usdtToken;
    IReferral public referralContract;
    ILock public lockContract;
    
    address public owner;
    bool public ownershipRenounced = false;
    bool public paused = false;
    uint256 private _guardCounter = 1;
    modifier nonReentrant() {
        require(_guardCounter == 1, "Course: reentrant");
        _guardCounter = 2;
        _;
        _guardCounter = 1;
    }

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
    function buyCourse(uint256 courseId) external whenNotPaused nonReentrant {
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
    function registerPromoter() external whenNotPaused nonReentrant {
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

        require(usdtToken.transfer(platformWallet, platformAmount),"Course: tf");
        require(usdtToken.transfer(poolWallet, poolAmount),"Course: tf");
        require(usdtToken.transfer(charityWallet, charityAmount),"Course: tf");
        totalCharity += charityAmount;
        emit CharityDeposited(charityAmount);

        // 推广者的推荐人拿直推
        if (ref != address(0)) {
            uint8 refLevel = referralContract.getTeamLevel(ref);
            bool refIsPromoter = referralContract.isPromoter(ref);
            uint256 directRate = _getDirectRate(refLevel, refIsPromoter);
            uint256 directAmount = (fee * directRate) / RATE_DENOM;
            if (directAmount > 0 && directAmount <= platformAmount) {
                require(usdtToken.transfer(ref, directAmount), "Course: transfer failed");
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
    function releaseStudentStage2(address student) external whenNotPaused nonReentrant {
        StudentRecord storage s = students[student];
        require(s.aceAllocated > 0, "Course: no allocation");
        require(s.coursesCompleted >= 1, "Course: need complete 1 course");
        require(s.aceReleased < s.aceAllocated, "Course: all released");

        lockContract.releaseStudent(student, 1);
        uint256 releaseAmount = (s.aceAllocated * 30) / 100;
        s.aceReleased += releaseAmount;
        emit StudentACEReleased(student, 1, releaseAmount);
    }

    function releaseStudentStage3(address student) external whenNotPaused nonReentrant {
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
    function releasePromoterMonthly(address promoter) external whenNotPaused nonReentrant {
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

    function releasePromoterByLevel(address promoter, uint8 newLevel) external whenNotPaused nonReentrant {
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
    function refundCourse(address student) external whenNotPaused nonReentrant {
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
        uint256 directAmount = (amount * _getDirectRate(refLevel, referralContract.isPromoter(ref))) / RATE_DENOM;

        // 逐笔转账，复用变量减少栈压力
        if (directAmount > 0) require(usdtToken.transfer(ref, directAmount),"Course: tf");

        // 底池 20%
        require(usdtToken.transfer(poolWallet, (amount * POOL_RATE) / RATE_DENOM),"Course: tf");

        // 公益基金 1%
        uint256 charityAmount = (amount * CHARITY_RATE) / RATE_DENOM;
        require(usdtToken.transfer(charityWallet, charityAmount),"Course: tf");

        // 平台运营 = 剩余（底池+学员ACE+团队+公益+直推扣除）
        // 学员ACE 20% + 团队4% 留在合约供后续分配
        uint256 sent = directAmount
            + (amount * POOL_RATE) / RATE_DENOM
            + charityAmount
            + (amount * STUDENT_ACE_RATE) / RATE_DENOM   // 学员ACE
            + (amount * TEAM_REWARD_RATE) / RATE_DENOM;  // 团队
        if (sent < amount) require(usdtToken.transfer(platformWallet, amount - sent),"Course: tf");

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
        require(IERC20(token).transfer(msg.sender, amount),"Course: rescue failed");
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
