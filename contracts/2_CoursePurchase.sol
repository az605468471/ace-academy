// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ACE Course Purchase Contract v2 (方向/套餐模型)
 * @dev 阿奇学院课程购买合约
 *
 * 产品：
 *  P0 体验课 200U   → 解锁1节自制体验课
 *  P1 方向   500U   → 解锁1个方向(该方向所有课)
 *  P2 4方向  1500U  → 解锁4个方向
 *  P3 至尊   5000U  → 全部当前+未来新增方向,终身
 *
 * 功能：
 *  1. 按unicode"方向/套餐"购买(而非单门课)
 *  2. 用户解锁方向/至尊记录, 判定可访问
 *  3. USDT收付 → 资金分配(直推/底池/公益/学员ACE)
 *  4. 学员代币分阶段释放(30%+30%+40%)
 *  5. 推广者代币按月/级别释放
 *  6. 退课 → 释放全部剩余代币
 *  7. 体验课独立解锁
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
        require(_guardCounter == 1, "Course: reentrantunicode");
        _guardCounter = 2;
        _;
        _guardCounter = 1;
    }

    // 钱包
    address public platformWallet;      // 平台运营
    address public charityWallet;       // 公益基金
    address public poolWallet;          // 底池注入（临时存放，定期加底池）

    // ACE价格 (精度1e18, 1 ACE = acePrice/1e18 USDT)
    uint256 public acePrice;
    uint256 public lastPriceUpdate;

    // 统计
    uint256 public totalStudents;
    uint256 public totalRevenue;
    uint256 public totalCharity;

    // 体验课
    bool public trialCourseActive = true;
    uint256 public trialPrice = 200 * 10**18; // 200U
    struct TrialHold {
        bool bought;
    }
    mapping(address => TrialHold) public trialHold;

    // ============ 方向 (Direction) ============
    struct Direction {
        string name;      // 方向名
        bool active;      // 是否上架
    }
    mapping(uint256 => Direction) public directions;
    uint256 public directionCount;
    // 方向标识符(code) → id 索引 (用于前端/管理)
    mapping(string => uint256) public directionIdByCode;

    // ============ 套餐 (Package) ============
    // id: 1=方向(500U), 2=4方向(1500U), 3=至尊(5000U)
    struct Package {
        uint256 price;       // USDT
        uint256 dirCount;    // 解锁方向数 (0=至尊全部)
        bool allAccess;      // 是否全部+未来
        uint256 aceBonusMul; // ACE赠送系数 (1000=1.0, 1200=1.2, 1500=1.5)
        bool active;
    }
    mapping(uint256 => Package) public packages;

    // ============ 用户购买记录 ============
    struct StudentRecord {
        uint256 totalPaid;          // 总付费USDT
        uint256 aceAllocated;       // 分配的ACE总量
        uint256 aceReleased;        // 已释放的ACE
        bool examPassed;            // 是否考试通过
        bool refunded;              // 是否已退课
    }
    mapping(address => StudentRecord) public students;
    address[] public allStudents;

    // 用户解锁的方向 (方向ID数组)
    mapping(address => uint256[]) public userDirections;
    // 用户是否至尊(全部+未来)
    mapping(address => bool) public userAllAccess;

    // 推广者记录 (保留)
    struct PromoterRecord {
        uint256 paidAmount;
        uint256 aceAllocated;
        uint256 aceReleased;
        uint8 lastReleaseMonth;
        uint8 teamLevel;
        bool active;
    }
    mapping(address => PromoterRecord) public promoters;

    // 分配比例
    uint256 public constant DIRECT_RATE_MAX = 2800;
    uint256 public constant POOL_RATE = 2000;     // 20%底池
    uint256 public constant STUDENT_ACE_RATE = 2000; // 20%等值代币
    uint256 public constant TEAM_REWARD_RATE = 400;  // 4%团队
    uint256 public constant CHARITY_RATE = 100;      // 1%公益
    uint256 public constant RATE_DENOM = 10000;

    // 事件
    event CoursePurchased(address indexed student, uint256 packageId, uint256 price, uint256 aceAmount);
    event TrialPurchased(address indexed student, uint256 price);
    event DirectionUnlocked(address indexed student, uint256 directionId);
    event AllAccessUnlocked(address indexed student);
    event StudentACEReleased(address indexed student, uint8 stage, uint256 amount);
    event PromoterRegistered(address indexed promoter, uint256 paidAmount, uint256 aceAmount);
    event CourseRefunded(address indexed student, uint256 aceReleased);
    event CharityDeposited(uint256 amount);
    event DirectionAdded(uint256 indexed directionId, string name);
    event PackageUpdated(uint256 indexed packageId, uint256 price);

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
        address _poolWallet,
        address _owner
    ) {
        require(_aceToken != address(0) && _usdt != address(0), "Course: zero addressunicode");
        aceToken = IACEToken(_aceToken);
        usdtToken = IERC20(_usdt);
        platformWallet = _platformWallet;
        charityWallet = _charityWallet;
        poolWallet = _poolWallet;
        owner = _owner;
        acePrice = 1 * 10**16; // 0.01 USDT per ACE (初始0.1U? 注: 方案初始价0.1U, 这里设0.01U为1e16; 实际改0.1U为1e17)
        // 按方案初始价 0.1U = 1e17
        acePrice = 1 * 10**17; // 0.1 USDT per ACE
        lastPriceUpdate = block.timestamp;

        // 初始化5个方向 (code → name)
        _addDirection("ai", unicode"AI应用");
        _addDirection("ecom", unicode"跨境电商");
        _addDirection("block", unicode"区块链");
        _addDirection("mkt", unicode"数字营销");
        _addDirection("code", unicode"编程开发");

        // 初始化套餐
        packages[1] = Package(500 * 10**18, 1, false, 1000, true);   // 方向 500U, 1方向, 1.0x
        packages[2] = Package(1500 * 10**18, 4, false, 1200, true);  // 4方向 1500U, 1.2x
        packages[3] = Package(5000 * 10**18, 0, true, 1500, true);   // 至尊 5000U, 全部, 1.5x
    }

    function _addDirection(string memory code, string memory name) internal {
        directionCount++;
        directions[directionCount] = Direction(name, true);
        directionIdByCode[code] = directionCount;
    }

    // ============ 体验课购买 ============
    function buyTrial() external whenNotPaused nonReentrant {
        require(trialCourseActive, "Course: trial inactive");
        require(!trialHold[msg.sender].bought, "Course: trial already bought");

        address ref = getReferrerOrFail(msg.sender);
        require(usdtToken.transferFrom(msg.sender, address(this), trialPrice), "Course: USDT failedunicode");

        _distributeFunds(trialPrice, msg.sender, ref);

        // 记录
        _addStudentPaid(msg.sender, trialPrice);
        trialHold[msg.sender].bought = true;
        totalRevenue += trialPrice;

        emit TrialPurchased(msg.sender, trialPrice);
    }

    // ============ 购买套餐 (方向/4方向/至尊) ============
    // packageId: 1=方向, 2=4方向, 3=至尊
    function buyPackage(uint256 packageId, uint256[] calldata dirIds) external whenNotPaused nonReentrant {
        Package storage p = packages[packageId];
        require(p.active, "Course: package inactive");
        require(p.price > 0, "Course: invalid packageunicode");

        address ref = getReferrerOrFail(msg.sender);

        // 校验方向数量
        if (p.allAccess) {
            // 至尊: 无需指定方向, 解锁全部
            require(dirIds.length == 0 || dirIds.length == directionCount, "Course: no dirs for all");
            require(userDirections[msg.sender].length == 0, "Course: upgrade only once");
            require(!userAllAccess[msg.sender], "Course: already all access");
        } else {
            require(dirIds.length == p.dirCount, "Course: dir count mismatch");
        }

        require(usdtToken.transferFrom(msg.sender, address(this), p.price), "Course: USDT failedunicode");

        // 分配资金
        _distributeFunds(p.price, msg.sender, ref);

        // 计算ACE赠送 (按赠送系数)
        uint256 aceAmount;
        if (p.allAccess) {
            aceAmount = (p.price * p.aceBonusMul) / 1000 / acePrice; // USD值→ACE
        } else {
            aceAmount = (p.price * p.aceBonusMul) / 1000 / acePrice;
        }

        // 发放ACE (分阶段: 先锁到Lock, 释放30%)
        if (aceAmount > 0) {
            require(aceToken.transfer(address(lockContract), aceAmount), "Course: ACE transfer failedunicode");
            lockContract.depositStudent(msg.sender, aceAmount);
        }

        // 解锁方向
        if (p.allAccess) {
            userAllAccess[msg.sender] = true;
            emit AllAccessUnlocked(msg.sender);
        } else {
            for (uint256 i = 0; i < dirIds.length; i++) {
                require(dirIds[i] >= 1 && dirIds[i] <= directionCount, "Course: invalid dirunicode");
                if (!_hasDirection(msg.sender, dirIds[i])) {
                    userDirections[msg.sender].push(dirIds[i]);
                    emit DirectionUnlocked(msg.sender, dirIds[i]);
                }
            }
        }

        // 记录学员
        StudentRecord storage s = students[msg.sender];
        if (s.totalPaid == 0) { allStudents.push(msg.sender); totalStudents++; }
        s.totalPaid += p.price;
        s.aceAllocated += aceAmount;

        // 释放第一阶段30%
        if (aceAmount > 0) {
            lockContract.releaseStudent(msg.sender, 0);
            uint256 releaseAmount = (aceAmount * 30) / 100;
            s.aceReleased += releaseAmount;
            emit StudentACEReleased(msg.sender, 0, releaseAmount);
        }

        // 更新团队业绩
        if (address(referralContract) != address(0)) {
            referralContract.updateTeamStats(msg.sender, p.price);
        }

        totalRevenue += p.price;
        emit CoursePurchased(msg.sender, packageId, p.price, aceAmount);
    }

    // ============ 辅助 ============
    function getReferrerOrFail(address user) internal view returns (address) {
        address ref = referralContract.referrer(user);
        require(ref != address(0), "Course: need referrerunicode");
        return ref;
    }

    function _hasDirection(address user, uint256 dirId) internal view returns (bool) {
        uint256[] storage ds = userDirections[user];
        for (uint256 i = 0; i < ds.length; i++) {
            if (ds[i] == dirId) return true;
        }
        return false;
    }

    function _addStudentPaid(address user, uint256 amount) internal {
        StudentRecord storage s = students[user];
        if (s.totalPaid == 0) { allStudents.push(user); totalStudents++; }
        s.totalPaid += amount;
    }

    // ============ 查询: 解锁判定 ============
    function hasAccessToDirection(address user, uint256 dirId) public view returns (bool) {
        if (userAllAccess[user]) return true;
        return _hasDirection(user, dirId);
    }

    function hasTrial(address user) external view returns (bool) {
        return trialHold[user].bought;
    }

    function getUnlockedDirections(address user) external view returns (uint256[] memory) {
        return userDirections[user];
    }

    function isAllAccess(address user) external view returns (bool) {
        return userAllAccess[user];
    }

    // ============ 资金分配 (保留原逻辑) ============
    function _distributeFunds(uint256 amount, address student, address ref) internal {
        uint8 refLevel = referralContract.getTeamLevel(ref);
        uint256 directAmount = (amount * _getDirectRate(refLevel, referralContract.isPromoter(ref))) / RATE_DENOM;
        if (directAmount > 0) require(usdtToken.transfer(ref, directAmount), "Course: tf");

        require(usdtToken.transfer(poolWallet, (amount * POOL_RATE) / RATE_DENOM), "Course: tf");
        uint256 charityAmount = (amount * CHARITY_RATE) / RATE_DENOM;
        require(usdtToken.transfer(charityWallet, charityAmount), "Course: tf");

        uint256 sent = directAmount
            + (amount * POOL_RATE) / RATE_DENOM
            + charityAmount
            + (amount * STUDENT_ACE_RATE) / RATE_DENOM
            + (amount * TEAM_REWARD_RATE) / RATE_DENOM;
        if (sent < amount) require(usdtToken.transfer(platformWallet, amount - sent), "Course: tfunicode");

        totalCharity += charityAmount;
        emit CharityDeposited(charityAmount);
    }

    function _getDirectRate(uint8 level, bool isPromoter) internal pure returns (uint256) {
        uint256[5] memory studentRates = [uint256(1500), uint256(1700), uint256(1900), uint256(2100), uint256(2300)];
        uint256[5] memory promoterRates = [uint256(2000), uint256(2200), uint256(2400), uint256(2600), uint256(2800)];
        if (level > 4) level = 4;
        return isPromoter ? promoterRates[level] : studentRates[level];
    }

    // ============ 退课 (保留: 只退ACE, examPassed不可退) ============
    function refundCourse(address student) external whenNotPaused nonReentrant {
        StudentRecord storage s = students[student];
        require(s.aceAllocated > 0, "Course: no allocation");
        require(!s.refunded, "Course: already refunded");
        require(!s.examPassed, "Course: exam passed, no refundunicode");

        uint256 remaining = s.aceAllocated - s.aceReleased;
        if (remaining > 0) {
            lockContract.releaseAllOnRefund(student);
            s.aceReleased = s.aceAllocated;
        }
        s.refunded = true;
        emit CourseRefunded(student, remaining);
    }

    // ============ 学员代币释放 ============
    function releaseStudentStage2(address student) external whenNotPaused nonReentrant {
        StudentRecord storage s = students[student];
        require(s.aceAllocated > 0, "Course: no allocation");
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
        require(s.aceReleased < s.aceAllocated, "Course: all releasedunicode");
        lockContract.releaseStudent(student, 2);
        uint256 releaseAmount = (s.aceAllocated * 40) / 100;
        s.aceReleased += releaseAmount;
        emit StudentACEReleased(student, 2, releaseAmount);
    }

    // ============ 推广者释放 (保留) ============
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
        emit PromoterRegistered(promoter, p.aceReleased, releaseAmount);
    }

    function releasePromoterByLevel(address promoter, uint8 newLevel) external whenNotPaused nonReentrant {
        PromoterRecord storage p = promoters[promoter];
        require(p.active, "Course: not active");
        require(newLevel > p.teamLevel, "Course: level not increasedunicode");
        lockContract.releasePromoterByLevel(promoter, newLevel);
        uint256 releaseAmount = (p.aceAllocated * 10) / 100;
        p.aceReleased += releaseAmount;
        p.teamLevel = newLevel;
        emit PromoterRegistered(promoter, p.aceReleased, releaseAmount);
    }

    function _getCurrentMonth() internal view returns (uint8) {
        return uint8((block.timestamp / 30 days) % 12 + 1);
    }

    // ============ 管理函数 ============
    function addDirection(string calldata code, string calldata name) external onlyOwner {
        _addDirection(code, name);
        emit DirectionAdded(directionCount, name);
    }

    function setDirectionActive(uint256 id, bool active) external onlyOwner {
        directions[id].active = active;
    }

    function updatePackage(uint256 id, uint256 price, bool active) external onlyOwner {
        packages[id].price = price;
        packages[id].active = active;
    }

    function setTrialActive(bool flag) external onlyOwner { trialCourseActive = flag; }
    function setTrialPrice(uint256 price) external onlyOwner { trialPrice = price; }
    function updateAcePrice(uint256 newPrice) external onlyOwner { acePrice = newPrice; lastPriceUpdate = block.timestamp; }
    function markExamPassed(address student) external onlyOwner { students[student].examPassed = true; }

    function setReferralContract(address _ref) external onlyOwner { referralContract = IReferral(_ref); }
    function setLockContract(address _lock) external onlyOwner { lockContract = ILock(_lock); }
    function setPlatformWallet(address w) external onlyOwner { platformWallet = w; }
    function setCharityWallet(address w) external onlyOwner { charityWallet = w; }
    function setPoolWallet(address w) external onlyOwner { poolWallet = w; }
    function pause() external onlyOwner { paused = true; }
    function unpause() external onlyOwner { paused = false; }
    function transferOwnership(address newOwner) external onlyOwner { require(newOwner != address(0),"zero"); owner = newOwner; }
    function renounceOwnership() external onlyOwner { ownershipRenounced = true; }

    function rescueToken(address token, uint256 amount) external onlyOwner {
        require(token != address(aceToken), "Course: cannot rescue ACE");
        require(IERC20(token).transfer(msg.sender, amount), "Course: rescue failed");
    }

    // ============ 查询 ============
    function getStudentInfo(address student) external view returns (
        uint256 totalPaid, uint256 aceAllocated, uint256 aceReleased,
        bool examPassed, bool refunded
    ) {
        StudentRecord storage s = students[student];
        return (s.totalPaid, s.aceAllocated, s.aceReleased, s.examPassed, s.refunded);
    }

    function getPromoterInfo(address promoter) external view returns (
        uint256 paidAmount, uint256 aceAllocated, uint256 aceReleased,
        uint8 lastReleaseMonth, uint8 teamLevel, bool active
    ) {
        PromoterRecord storage p = promoters[promoter];
        return (p.paidAmount, p.aceAllocated, p.aceReleased, p.lastReleaseMonth, p.teamLevel, p.active);
    }

    function getStats() external view returns (
        uint256 _totalStudents, uint256 _totalRevenue, uint256 _totalCharity,
        uint256 _acePrice, uint256 _trialPrice, uint256 _directionCount
    ) {
        return (totalStudents, totalRevenue, totalCharity, acePrice, trialPrice, directionCount);
    }

    function getDirectionCount() external view returns (uint256) { return directionCount; }

    function getPackage(uint256 id) external view returns (
        uint256 price, uint256 dirCount, bool allAccess, uint256 aceBonusMul, bool active
    ) {
        Package storage p = packages[id];
        return (p.price, p.dirCount, p.allAccess, p.aceBonusMul, p.active);
    }
}
