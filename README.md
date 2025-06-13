# 🏦 PiggyBank - 이더리움 스마트 컨트랙트

## 🛠️ 프로젝트 개요

> **PiggyBank**는 개인 계좌와 공용 계좌 기능을 제공하는 이더리움 기반 스마트 컨트랙트 프로젝트입니다.
> 사용자는 자신의 자산을 안전하게 보관하고, 타인과의 공유 계좌를 통해 협업적인 자금 운영이 가능합니다.

---

## ✨ 주요 기능

### 🔒 개인 계좌 (Private Account)

- 사용자 1명당 하나의 개인 계좌만 생성 가능
- 개인 잔액 관리
- 타인이 접근 불가

### 👥 공용 계좌 (Public Account)

- 누구나 고유한 계좌 ID로 공용 계좌 생성 가능
- 생성자는 해당 계좌의 **소유자(owner)**가 됨
- 세부 권한 관리 기능 제공:
  - ✅ 특정 사용자에 대한 입금/출금 권한 부여 및 회수
  - 📈 사용자별 입금 한도 / 출금 한도 설정
  - 🔐 접근 통제 (특정 사용자 차단 가능)

---

## 🧱 컨트랙트 구조

### ✅ 주요 변수 및 구조체

```solidity
mapping(address => uint256) private balances;
mapping(address => bool) private hasAccount;
mapping(bytes32 => PublicAccount) publicAccounts;

struct PublicAccount {
    address owner;
    mapping(address => bool) access;
    mapping(address => uint256) depositLimits;
    mapping(address => uint256) withdrawLimits;
    mapping(address => uint256) balances;
}
```

---

## 🗂️ 프로젝트 구조

```
piggybank
├── contracts/
│   ├── AccessControl.sol       # 권한 로직 관리
│   └── PiggyBank.sol           # 기능 구현현
├── test/
│   ├── PiggyBank.private.sol   # 개인계좌 기능 테스트 코드
│   └── PiggyBank.public.sol    # 공용계좌 기능 테스트 코드
├── hardhat.config.js
├── package.json
└── README.md
```
