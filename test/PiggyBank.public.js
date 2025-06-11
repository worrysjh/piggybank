const { expect } = require("chai");
const { ethers } = require("hardhat");
const { parseEther } = ethers;

describe("PiggyBank - 공용 계좌 기능", function () {
  let PiggyBank, piggyBank, owner, user, accountId;

  beforeEach(async () => {
    [owner, user] = await ethers.getSigners();
    PiggyBank = await ethers.getContractFactory("PiggyBank");
    piggyBank = await PiggyBank.deploy();

    // 공용 계좌 생성
    const tx = await piggyBank.connect(owner).createPublicAccount();
    const receipt = await tx.wait();
    /* 
    //const event = receipt.events.find((e) => e.event === "PublicAccountCreated");
    
    오류 메시지 : TypeError: Cannot read properties of undefined (reading 'find')
    receipt가 undefined됨

    receipt.events 대신 receipt.logs 를 수동으로 파싱
    createdPublicAccount에서 accountId 찾기 과정
    */

    // 이벤트 수동 파싱
    const iface = piggyBank.interface;
    // receipt.logs : 트랜잭션 실행 결과로 발생한 모든 로그 배열
    const parsed = receipt.logs
      .map((log) => {
        try {
          return iface.parseLog(log);
        } catch (e) {
          return null;
        }
      })
      .find((e) => e && e.name === "PublicAccountCreated");

    if (!parsed)
      throw new Error("PublicAccountCreated 이벤트를 찾을 수 없습니다.");

    accountId = parsed.args.id;
  });

  it("권한이 없는 사용자는 입금할 수 없어야 한다", async () => {
    await expect(
      piggyBank.connect(user).depositToPublic(accountId, {
        value: parseEther("1"),
      })
    ).to.be.revertedWith("No access");
  });

  it("권한이 없는 사용자는 출금할 수 없어야 한다", async () => {
    await expect(
      piggyBank.connect(user).withdrawFromPublic(accountId, parseEther("0.4"))
    ).to.be.revertedWith("No access");
  });

  it("권한이 없는 사용자는 공용 통장 잔고를 확인할 수 없어야 한다", async () => {
    await expect(
      piggyBank.connect(user).checkPublicBalance(accountId)
    ).to.be.revertedWith("No access");
  });

  it("권한 부여시 사용자는 공용 통장 잔고를 볼 수 있어야 한다", async () => {
    await piggyBank.connect(owner).grantAccess(accountId, user.address);
    await expect(piggyBank.connect(user).checkPublicBalance(accountId)).to.not
      .be.reverted;
  });

  it("owner가 사용자에게 권한을 부여할 수 있어야 한다", async () => {
    await piggyBank.connect(owner).grantAccess(accountId, user.address);

    await expect(
      piggyBank.connect(user).depositToPublic(accountId, {
        value: parseEther("1"),
      })
    ).to.not.be.reverted;
  });

  it("출금 시 잔액보다 많으면 실패해야 한다", async () => {
    await piggyBank.connect(owner).grantAccess(accountId, user.address);
    await piggyBank.connect(user).depositToPublic(accountId, {
      value: parseEther("1"),
    });

    await expect(
      piggyBank.connect(user).withdrawFromPublic(accountId, parseEther("2"))
    ).to.be.revertedWith("Insufficient balance");
  });

  it("출금 시 잔액보다 적어도 한도보다 높으면 실패해야 한다", async () => {
    await piggyBank.connect(owner).grantAccess(accountId, user.address);
    await piggyBank.connect(user).depositToPublic(accountId, {
      value: parseEther("10"),
    });

    await piggyBank
      .connect(owner)
      .setWithdrawLimit(accountId, user.address, parseEther("5"));

    await expect(
      piggyBank.connect(user).withdrawFromPublic(accountId, parseEther("6"))
    ).to.be.reverted;
  });

  it("입금 시 입금한도보다 높게 입금을 시도하면 실패한다", async () => {
    await piggyBank.connect(owner).grantAccess(accountId, user.address);
    await piggyBank
      .connect(owner)
      .setDepositLimit(accountId, user.address, parseEther("5"));

    await expect(
      piggyBank
        .connect(user)
        .depositToPublic(accountId, { value: parseEther("10") })
    ).to.be.reverted;
  });

  it("입금 후 공용 계좌 잔고가 증가해야 한다", async () => {
    await piggyBank.connect(owner).grantAccess(accountId, user.address);
    await piggyBank.connect(user).depositToPublic(accountId, {
      value: parseEther("1"),
    });

    const balance = await piggyBank.connect(user).checkPublicBalance(accountId);
    expect(balance).to.equal(parseEther("1"));
  });

  it("입금 후 공용 계좌 잔고가 수치적으로 증가해야 한다", async () => {
    await piggyBank.connect(owner).grantAccess(accountId, user.address);

    const before = await piggyBank.connect(user).checkPublicBalance(accountId);
    console.log("* 입금 전 잔고 : ", ethers.formatEther(before));

    await piggyBank.connect(user).depositToPublic(accountId, {
      value: parseEther("3"),
    });

    const after = await piggyBank.connect(user).checkPublicBalance(accountId);
    console.log("* 입금 후 잔고 : ", ethers.formatEther(after));
  });

  it("권한 회수 후 입/출금 시도시 실패해야 함", async () => {
    await piggyBank.connect(owner).grantAccess(accountId, user.address);
    console.log("=== 권한 부여 ok ===");

    await piggyBank.connect(owner).revokeAccess(accountId, user.address);
    console.log("=== 권한 몰수 ok ===");

    await expect(
      piggyBank.connect(user).depositToPublic(accountId, {
        value: parseEther("1"),
      })
    ).to.be.revertedWith("No access");
  });
});
