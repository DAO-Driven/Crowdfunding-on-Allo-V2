require('dotenv').config();
const { expect } = require("chai");
const { ethers } = require("hardhat");
const colors = require('colors');
const hatsAbi = require('./hats/hatAbi.json');
const mainHatKey = process.env.TOP_HAT_PRIVATE_KEY;
const hatsAddress = "0x3bc1A0Ad72417f2d411118085256fC53CBdDd137";    
const alloAddress = "0x1133eA7Af70876e64665ecD07C0A0476d09465a1";
const hatID = process.env.MANAGER_HAT_ID;
const mainHAT = new ethers.Wallet(mainHatKey, ethers.provider);

describe("Contract Deployment", function () {
  let managerContract, executorSupplierVotingStrategy;
  let deployer, profileId, poolId;
  let strategyName = "Executor-Supplier-Voting";
  let deployerPrivateKey = process.env.TEST_DEPLOYER_KEY;
  let testRecipientAddress = process.env.TEST_RECIPIENT_ADDRESS;

  before(async function () {
    // Use the first account as the deployer
    deployer = new ethers.Wallet(deployerPrivateKey, ethers.provider);

    const ExecutorSupplierVotingStrategy = await ethers.getContractFactory("ExecutorSupplierVotingStrategy", deployer);
    executorSupplierVotingStrategy = await ExecutorSupplierVotingStrategy.deploy(alloAddress, strategyName);
    await executorSupplierVotingStrategy.deployed();

    const StrategyFactory = await ethers.getContractFactory("StrategyFactory", deployer);
    const strategyFactory = await StrategyFactory.deploy();
    await strategyFactory.deployed();

    const ManagerContractInstance = await ethers.getContractFactory("Manager", deployer);
    managerContract = await ManagerContractInstance.deploy(
      alloAddress, 
      executorSupplierVotingStrategy.address, 
      strategyFactory.address,
      hatsAddress,
      hatID
    );

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

  it("Should transfer the hat to Manager", async function () {
    const hatsContract = await ethers.getContractAt(
        hatsAbi, 
        hatsAddress, 
        mainHAT
    );

    const hatId = hatID;

    // Check if supplier_1 is eligible
    const isEligible = await hatsContract.isEligible(managerContract.address, hatId);
    console.log(`Is supplier_1 eligible for Hat ID ${hatId}:`, isEligible);

    const isMainHatWearing = await hatsContract.isWearerOfHat(mainHAT.address, hatId);
    console.log(`Is mainHAT wearing Hat ID ${hatId}:`, isMainHatWearing);


    if (isEligible) {
        try {
            // Attempt to transfer the hat
          await hatsContract.transferHat(
              hatId, 
              mainHAT.address, 
              managerContract.address,
              { gasLimit: 3000000}
          );

          console.log(`Successfully transferred Hat ID ${hatId} to managerContract`);

        } catch (error) {
            console.error(`Error during transfer of Hat ID ${hatId}:`, error);
        }
    } else {
        console.log(`supplier_1 is not eligible to wear Hat ID ${hatId}`);
    }
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
        "Dev Profile 2", 
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
        "Dev Profile 3", 
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
        "Dev Profile 4", 
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
