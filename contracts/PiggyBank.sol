// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title PiggyBank - 개인 및 공용 계좌를 지원하는 이더리움 은행
/// @notice 사용자가 개인 또는 공용 계좌를 개설하고, 입출금할 수 있게 한다
contract PiggyBank {
    event PublicAccountCreated(bytes32 indexed id, address indexed owner);

    // ------------------------
    // 개인 계좌
    /// @notice 각 사용자의 잔액 저장
    mapping(address => uint256) private balances;

    /// @notice 계좌 개설 여부 확인
    mapping(address => bool) private hasAccount;

    /// @notice 개인 계좌를 개설한다. 한번만 개설 가능하다.
    /// @dev balances와 hasAccount 갱신
    function createAccount() external {
        require(!hasAccount[msg.sender], "Already has an account!");
        hasAccount[msg.sender] = true;
        balances[msg.sender] = 0;
    }

    /// @notice 개인 계좌에 입금할 수 있다.
    /// @dev msg.value만큼 balances에 추가
    function deposit() external payable {
        require(hasAccount[msg.sender], "Account not found");
        balances[msg.sender] += msg.value;
    }

    /// @notice 개인 계좌에서 출금할 수 있다.
    /// @dev amount가 balances보다 작으면 그만큼 balances에서 차감감
    function withdraw(uint256 amount) external {
        require(hasAccount[msg.sender], "Account not found");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    /// @notice 개인 계좌의 잔액을 조회할 수 있다.
    function checkBalance() external view returns (uint256) {
        require(hasAccount[msg.sender], "Account not found");
        return balances[msg.sender];
    }

    // ------------------------
    // 공용 계좌
    /// @notice 공용 계좌 구조
    struct PublicAccount {
        address owner;                              // 관리자(계설자)
        mapping(address => bool) access;            // 각 사용자 입출금 가능 여부
        mapping(address => uint256) depositLimit;   // 입금 한도
        mapping(address => uint256) withdrawLimit;  // 출금 한도
        mapping(address => uint256) balances;       // 잔액
    }

    mapping(bytes32 => PublicAccount) public publicAccounts;

    /// @notice 공용계좌 개설
    /// @dev 계좌 생성자(msg.sender)와 생성 시각(block.timestamp)을 조합해 유일한 값 해싱
    function createPublicAccount() external returns (bytes32) {
        bytes32 id = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        PublicAccount storage acc = publicAccounts[id];
        acc.owner = msg.sender;
        acc.access[msg.sender] = true;

        emit PublicAccountCreated(id, msg.sender);

        return id;
    }

    /// @notice 계좌 주인인가를 검사한다
    /// @dev modifier를 통해 전제 조건으로 검사
    modifier onlyOwner(bytes32 accountId) {
        require(publicAccounts[accountId].owner == msg.sender, "Not the account owner");
        _;
    }

    /// @notice 권한이 부여되었는가를 검사한다
    /// @dev modifier를 통해 전제 조건으로 검사
    modifier onlyAuthorized(bytes32 accountId) {
        require(publicAccounts[accountId].access[msg.sender], "No access");
        _;
    }

    /// @notice 특정 유저에게 접근 권한을 부여한다
    function grantAccess(bytes32 accountId, address user) external onlyOwner(accountId) {
        publicAccounts[accountId].access[user] = true;
    }

    /// @notice 특정 유저에게 접근 권한을 박탈한다
    function revokeAccess(bytes32 accountId, address user) external onlyOwner(accountId) {
        publicAccounts[accountId].access[user] = false;
    }

    /// @notice 특정 유저 입금 한도를 설정한다
    function setDepositLimit(bytes32 accountId, address user, uint256 limit) external onlyOwner(accountId) {
        publicAccounts[accountId].depositLimit[user] = limit;
    }

    /// @notice 특정 유저 출금 한도를 설정한다
    function setWithdrawLimit(bytes32 accountId, address user, uint256 limit) external onlyOwner(accountId) {
        publicAccounts[accountId].withdrawLimit[user] = limit;
    }

    /// @notice 공용계좌에 입금
    /// @dev 공용계좌(accountId)에 허가된(onlyAuthorized) 유저(msg.sender)의 입금액(msg.value)만큼 잔고(balances)에 추가
    function depositToPublic(bytes32 accountId) external payable onlyAuthorized(accountId) {
        uint256 limit = publicAccounts[accountId].depositLimit[msg.sender];
        require(limit == 0 || msg.value <= limit, "Deposit exceeds limit");
        publicAccounts[accountId].balances[msg.sender] += msg.value;
    }

    /// @notice 공용계좌에서 출금
    /// @dev 공용계좌(accountId)에 허가된(onlyAuthorized) 유저(msg.sender)의 한도(limit) 이하의 출금액(amount)만큼 잔고(balances)에서 차감
    function withdrawFromPublic(bytes32 accountId, uint256 amount) external onlyAuthorized(accountId) {
        uint256 limit = publicAccounts[accountId].withdrawLimit[msg.sender];
        require(limit == 0 || amount <= limit, "Withdraw exceeds limit");
        require(publicAccounts[accountId].balances[msg.sender] >= amount, "Insufficient balance");
        publicAccounts[accountId].balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    /// @notice 공용계좌 잔고 확인
    function checkPublicBalance(bytes32 accountId) external view onlyAuthorized(accountId) returns (uint256) {
        return publicAccounts[accountId].balances[msg.sender];
    }
}