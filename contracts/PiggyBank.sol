// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PiggyBank {
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
        address owner;
        mapping(address => bool) access;
        mapping(address => uint256) depositLimit;
        mapping(address => uint256) withdrawLimit;
        mapping(address => uint256) balances;
    }

    mapping(bytes32 => PublicAccount) public PublicAccounts;

    function createPublicAccount() external returns (bytes32) {
        bytes32 id = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        PublicAccount storage acc = publicAccounts[id];
        acc.owner = msg.sender;
        acc.access[msg.sender] = true;
        return id;
    }

    modifier onlyOwner(bytes32 accountId) {
        require(publicAccounts[accountId].owner == msg.sender, "Not the account owner");
        _;
    }

    modifier onlyAuthorized(bytes32 accountId) {
        require(publicAccounts[aacountId].access[msg.sender], "No access");
        _;
    }

    function grantAccess(bytes32 accountId, address user) external onlyOwner(accountId) {
        publicAccounts[accountId].access[user] = true;
    }

    function revokeAccess(bytes32 accountId, address user) external onlyOwner(accountId) {
        publicAccounts[accountId].access[user] = false;
    }

    function setDepositLimit(bytes32 accountId, address user, uint256 limit) external onlyOwner(accountId) {
        publicAccounts[accountId].depositLimit[user] = limit;
    }

    function setWithdrawLimit(bytes32 accountId, address user, uint256 limit) external onlyOwner(accountId) {
        publicAccounts[aacountId].withdrawLimit[user] = limit;
    }

    function depositToPublic(bytes32 accountId) external payable onlyAuthorized(accountId) {
        uint256 limit = publicAccounts[accountId].depositLimit[msg.sender];
        require(limit == 0 || msg.value <= limit, "Deposit exceeds limit");
        publicAccounts[accountId].balances[msg.sender] += msg.value;
    }

    function withdrawFromPublic(bytes32 accountId, uint256 amount) external onlyAuthorized(accountId) {
        uint256 limit = publicAccounts[accountId].withdrawLimit[msg.sender];
        require(limit == 0 || amout <= limit, "Withdraw exceeds limit");
        require(publicAccounts[accountId].balances[msg.sender] >= amount, "Insufficient balance");
        publicAccounts[accountId].balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function checkPublicBalance(bytes32 accountId) external view onlyAuthorized(accountId) returns (uint256) {
        return publicAccounts[accountId].balances[msg.sender];
    }
}