// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function burn(uint256 amount) external;
}

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

    constructor(address _aceToken, address _owner) {
        require(_aceToken != address(0), "Lock: zero address");
        aceToken = IERC20(_aceToken);
        owner = _owner;
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
            require(aceToken.transfer(BURN_ADDRESS, burnAmount), "Lock: burn failed");
            emit Burned(student, burnAmount);
        }
        if (sendAmount > 0) {
            require(aceToken.transfer(student, sendAmount), "Lock: send failed");
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
            require(aceToken.transfer(BURN_ADDRESS, burnAmount), "Lock: burn failed");
            emit Burned(promoter, burnAmount);
        }
        if (sendAmount > 0) {
            require(aceToken.transfer(promoter, sendAmount), "Lock: send failed");
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
            require(aceToken.transfer(promoter, releaseAmount), "Lock: send failed");
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
                require(aceToken.transfer(user, remaining), "Lock: send failed");
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
