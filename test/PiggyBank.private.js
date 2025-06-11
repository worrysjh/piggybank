const { expect } = require("chai");
const { ethers } = require("hardhat");
const { parseEther } = ethers; // ethers v6용

describe("PiggyBank - 개인 계좌 기능", function () {
  let PiggyBank, piggyBank, user;

  // 각 it 시작 전 실행필요
  beforeEach(async () => {
    [user] = await ethers.getSigners();
    PiggyBank = await ethers.getContractFactory("PiggyBank");
    piggyBank = await PiggyBank.deploy();
  });

  it("개인 계좌 생성 시 이벤트가 발생해야 한다", async () => {
    await expect(piggyBank.connect(user).createAccount())
      .to.emit(piggyBank, "PrivateAccountCreated")
      .withArgs(user.address);
  });

  it("계좌가 없는 사용자는 입금할 수 없어야 한다", async () => {
    await expect(
      piggyBank.connect(user).deposit({ value: parseEther("1") })
    ).to.be.revertedWith("Account not found");
  });

  it("계좌 개설 후 잔액이 0 이어야 한다", async () => {
    await piggyBank.connect(user).createAccount();
    await piggyBank.connect(user).deposit({ value: parseEther("1") });

    const balance = await piggyBank.connect(user).checkBalance();
    expect(balance).to.equal(parseEther("1"));
  });

  it("출금 후 잔액이 감소해야 한다", async () => {
    await piggyBank.connect(user).createAccount();
    await piggyBank.connect(user).deposit({ value: parseEther("1") });
    await piggyBank.connect(user).withdraw(parseEther("0.4"));

    const balance = await piggyBank.connect(user).checkBalance();
    expect(balance).to.equal(parseEther("0.6"));
  });

  it("출금 시 잔액보다 많으면 실패해야 한다", async () => {
    await piggyBank.connect(user).createAccount();
    await piggyBank.connect(user).deposit({ value: parseEther("1") });

    await expect(
      piggyBank.connect(user).withdraw(parseEther("2"))
    ).to.be.revertedWith("Insufficient balance");
  });
});
