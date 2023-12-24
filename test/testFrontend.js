const { expect } = require("chai");
const { ethers } = require("hardhat");
const colors = require('colors');

describe("Contract Deployment", function () {
  let managerContract, executorSupplierVotingStrategy;
  let deployer, profileId, poolId;
  let strategyName = "Executor-Supplier-Voting";
  let deployerPrivateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
  let testRecipientAddress = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
  let testRecipientPrivateKey = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";

  before(async function () {
    // Use the first account as the deployer
    deployer = new ethers.Wallet(deployerPrivateKey, ethers.provider);

    const ExecutorSupplierVotingStrategy = await ethers.getContractFactory("ExecutorSupplierVotingStrategy", deployer);
    executorSupplierVotingStrategy = await ExecutorSupplierVotingStrategy.deploy("0x1133eA7Af70876e64665ecD07C0A0476d09465a1", strategyName);
    await executorSupplierVotingStrategy.deployed();

    const alloAddress = "0x1133eA7Af70876e64665ecD07C0A0476d09465a1";
    const ManagerContractInstance = await ethers.getContractFactory("Manager", deployer);
    managerContract = await ManagerContractInstance.deploy(alloAddress, executorSupplierVotingStrategy.address);
    await managerContract.deployed();

    const fundAmount = ethers.utils.parseEther("10"); // 1 ether, for example
    const fundTx = await deployer.sendTransaction({
      to: managerContract.address,
      value: fundAmount
    });
    await fundTx.wait();

    console.log(colors.white(`Funded managerContract with ${fundAmount.toString()} wei`));

    const testContractBalance = await ethers.provider.getBalance(managerContract.address);
    console.log(colors.white(`managerContract balance is ${ethers.utils.formatEther(testContractBalance)} ETH`));
  });

  it("Should deploy the ExecutorSupplierVotingStrategy contract and return a valid address", async function () {
    expect(ethers.utils.isAddress(executorSupplierVotingStrategy.address)).to.be.true;
    console.log("ExecutorSupplierVotingStrategy Deployed Address:", executorSupplierVotingStrategy.address);
  });

  it("Should deploy the managerContract and return a valid address", async function () {
    expect(ethers.utils.isAddress(managerContract.address)).to.be.true;
    console.log("managerContract Deployed Address:", managerContract.address);
  });

  describe("managerContract Functionality", function () {

    it("Should successfully call registerProject and return a profile data\n\n", async function () {

      console.log(colors.white("\n\n================== managerContract Functionality test STARTS ==================\n\n")) 


      const tx = await managerContract.registerProject(
        ethers.utils.parseEther("1"),
        77777777, 
        "Dev Profile 1", 
        [1, "test pointer"], 
        testRecipientAddress,
        "Test Description"
      );

      const txReceipt = await tx.wait();
      profileId = txReceipt.events[2].topics[1];

      console.log(colors.white("================== Profile ID:"), profileId) 

      const getProfileById = await managerContract.getProfile(profileId);

      console.log(colors.white("================== GET new Profile by ID:"), getProfileById[0]) 
      console.log(getProfileById);
    });

    it("Should successfully create 3 Dev profiles and return Ids\n\n", async function () {

      console.log(colors.white("\n\n================== 3 DEV PROFILES ==================\n\n")) 

      const txDevProfile_1 = await managerContract.registerProject(
        ethers.utils.parseEther("1"),
        77779876, 
        "Dev Profile 1", 
        [1, "test pointer"], 
        testRecipientAddress,
        "Test Description"
      );

      const txReceiptDevProfile_1 = await txDevProfile_1.wait();
      const profileId_1 = txReceiptDevProfile_1.events[2].topics[1];
      console.log(colors.white("================== Profile ID:"), profileId_1)


      const txDevProfile_2 = await managerContract.registerProject(
        ethers.utils.parseEther("1"),
        7765479876, 
        "Dev Profile 2", 
        [1, "test pointer"], 
        testRecipientAddress,
        "Test Description"
      );

      const txReceiptDevProfile_2 = await txDevProfile_2.wait();
      const profileId_2 = txReceiptDevProfile_2.events[2].topics[1];

      console.log(colors.white("================== Profile ID:"), profileId_2)

      const txDevProfile_3 = await managerContract.registerProject(
        ethers.utils.parseEther("1"),
        7765411111, 
        "Dev Profile 2", 
        [1, "test pointer"], 
        testRecipientAddress,
        "Test Description"
      );

      const txReceiptDevProfile_3 = await txDevProfile_3.wait();
      const profileId_3 = txReceiptDevProfile_3.events[2].topics[1];

      console.log(colors.white("================== Profile ID:"), profileId_3)

    });
  })
});  
