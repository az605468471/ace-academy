// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

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
            require(aceToken.transfer(upline, reward), "Ref: reward failed");
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
        require(IERC20(token).transfer(msg.sender, amount), "Ref: rescue failed");
    }
}
