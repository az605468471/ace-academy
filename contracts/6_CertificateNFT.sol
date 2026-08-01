// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

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
