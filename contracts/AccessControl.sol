//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccessControl {
    // 공용 계좌
    /// @notice 공용 계좌 구조
    struct PublicAccount {
        address owner; // 관리자(계설자)
        mapping(address => bool) access; // 각 사용자 입출금 가능 여부
        mapping(address => uint256) depositLimit; // 입금 한도
        mapping(address => uint256) withdrawLimit; // 출금 한도
        mapping(address => uint256) balances; // 잔액
    }

    mapping(bytes32 => PublicAccount) internal publicAccounts;

    /// @notice 계좌 주인인가를 검사한다
    /// @dev modifier를 통해 전제 조건으로 검사
    modifier onlyOwner(bytes32 _accountId) {
        require(
            publicAccounts[_accountId].owner == msg.sender,
            "Not the account owner"
        );
        _;
    }

    /// @notice 권한이 부여되었는가를 검사한다
    /// @dev modifier를 통해 전제 조건으로 검사
    modifier onlyAuthorized(bytes32 _accountId) {
        require(publicAccounts[_accountId].access[msg.sender], "No access");
        _;
    }
}
