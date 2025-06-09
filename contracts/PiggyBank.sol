// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PiggyBank {
    event PublicAccountCreated(bytes32 indexed id, address indexed owner);


    // ------------------------
    // 개인 계좌
    //1. 각 사용자의 잔액 저장
    mapping(address => uint256) private balances;

    //2. 계좌 개설 여부 확인
    mapping(address => bool) private hasAccount;

    //3. 계좌 개설(최초 1회)
    function createAccount() external {
        require(!hasAccount[msg.sender], "Already has an account!");
        hasAccount[msg.sender] = true;
        balances[msg.sender] = 0;
    }

    //4. 입금
    function deposit() external payable {
        require(hasAccount[msg.sender], "Account not found");
        balances[msg.sender] += msg.value;
    }

    //5. 출금
    function withdraw(uint256 amount) external {
        require(hasAccount[msg.sender], "Account not found");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    //6. 잔액 조회
    function checkBalance() external view returns (uint256) {
        require(hasAccount[msg.sender], "Account not found");
        return balances[msg.sender];
    }

    // ------------------------
    // 공용 계좌
    struct PublicAccount {
        address owner;                              // 관리자(계설자)
        mapping(address => bool) access;            // 각 사용자 입출금 가능 여부
        mapping(address => uint256) depositLimit;   // 입금 한도
        mapping(address => uint256) withdrawLimit;  // 출금 한도
        mapping(address => uint256) balances;       // 잔액
    }

    mapping(bytes32 => PublicAccount) public publicAccounts;

    // 공용계좌 개설
    function createPublicAccount() external returns (bytes32) {
        bytes32 id = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        PublicAccount storage acc = publicAccounts[id];
        acc.owner = msg.sender;
        acc.access[msg.sender] = true;

        emit PublicAccountCreated(id, msg.sender);

        return id;
    }

    // 계좌 주인인가?
    modifier onlyOwner(bytes32 accountId) {
        require(publicAccounts[accountId].owner == msg.sender, "Not the account owner");
        _;
    }

    // 권한이 부여되었는가?
    modifier onlyAuthorized(bytes32 accountId) {
        require(publicAccounts[accountId].access[msg.sender], "No access");
        _;
    }

    // 특정 유저에게 권한 부여
    function grantAccess(bytes32 accountId, address user) external onlyOwner(accountId) {
        publicAccounts[accountId].access[user] = true;
    }

    // 특정 유저에게 권한 몰수
    function revokeAccess(bytes32 accountId, address user) external onlyOwner(accountId) {
        publicAccounts[accountId].access[user] = false;
    }

    // 특정 유저 입금 한도 설정
    function setDepositLimit(bytes32 accountId, address user, uint256 limit) external onlyOwner(accountId) {
        publicAccounts[accountId].depositLimit[user] = limit;
    }

    // 특정 유저 출금 한도 설정
    function setWithdrawLimit(bytes32 accountId, address user, uint256 limit) external onlyOwner(accountId) {
        publicAccounts[accountId].withdrawLimit[user] = limit;
    }

    // 공용계좌에 입금
    function depositToPublic(bytes32 accountId) external payable onlyAuthorized(accountId) {
        uint256 limit = publicAccounts[accountId].depositLimit[msg.sender];
        require(limit == 0 || msg.value <= limit, "Deposit exceeds limit");
        publicAccounts[accountId].balances[msg.sender] += msg.value;
    }

    // 공용계좌에서 출금
    function withdrawFromPublic(bytes32 accountId, uint256 amount) external onlyAuthorized(accountId) {
        uint256 limit = publicAccounts[accountId].withdrawLimit[msg.sender];
        require(limit == 0 || amount <= limit, "Withdraw exceeds limit");
        require(publicAccounts[accountId].balances[msg.sender] >= amount, "Insufficient balance");
        publicAccounts[accountId].balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // 공용계좌 잔고 확인
    function checkPublicBalance(bytes32 accountId) external view onlyAuthorized(accountId) returns (uint256) {
        return publicAccounts[accountId].balances[msg.sender];
    }
}