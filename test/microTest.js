const { expect } = require("chai");
const { ethers } = require("hardhat");
const colors = require('colors');


describe("Contract Deployment", function () {
  let testContract, directGrantsSimpleStrategy;
  let deployer, profileId, poolId;
  let strategyName = "MicroGrants-Strategy";
  let deployerPrivateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"; // Account #0 Private Key

  before(async function () {
    // Use the first account as the deployer
    deployer = new ethers.Wallet(deployerPrivateKey, ethers.provider);

    const DirectGrantsSimpleStrategy = await ethers.getContractFactory("DirectGrantsSimpleStrategy", deployer);
    directGrantsSimpleStrategy = await DirectGrantsSimpleStrategy.deploy("0x1133eA7Af70876e64665ecD07C0A0476d09465a1", strategyName);
    await directGrantsSimpleStrategy.deployed();

    // Deploy TestContract
    const TestContract = await ethers.getContractFactory("TestContract", deployer);
    testContract = await TestContract.deploy();
    await testContract.deployed();

    const fundAmount = ethers.utils.parseEther("10"); // 1 ether, for example
    const fundTx = await deployer.sendTransaction({
      to: testContract.address,
      value: fundAmount
    });
    await fundTx.wait();

    console.log(colors.white(`Funded TestContract with ${fundAmount.toString()} wei`));

    const testContractBalance = await ethers.provider.getBalance(testContract.address);
    console.log(colors.white(`TestContract balance is ${ethers.utils.formatEther(testContractBalance)} ETH`));
  });

  it("Should deploy the DirectGrantsSimpleStrategy contract and return a valid address", async function () {
    expect(ethers.utils.isAddress(directGrantsSimpleStrategy.address)).to.be.true;
    console.log("DirectGrantsSimpleStrategy Deployed Address:", directGrantsSimpleStrategy.address);
  });

  it("Should deploy the TestContract and return a valid address", async function () {
    expect(ethers.utils.isAddress(testContract.address)).to.be.true;
    console.log("TestContract Deployed Address:", testContract.address);
  });

  describe("TestContract Functionality", function () {
  
    it("Should successfully call getAlloRegistry and return a valid address", async function () {
      // Call the function
      const registryAddress = await testContract.getAlloRegistry();
  
      // Check if the returned value is a valid Ethereum address
      expect(ethers.utils.isAddress(registryAddress)).to.be.true;
      console.log("Returned Registry Address:", registryAddress);
    });

    it("Should successfully call createProfile and return a profile data", async function () {
      const tx = await testContract.createProfile(
        77777777, 
        "Dev Profile 1", 
        [1, "test pointer"], 
        testContract.address, 
        [testContract.address, "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"]
      );

      const txReceipt = await tx.wait();
      profileId = txReceipt.events[2].topics[1];

      console.log("Profile ID:", profileId);

      const getProfileById = await testContract.getProfile(profileId);

      console.log("GET Profile by ID:", getProfileById);
    });

    it("Should successfully call createPoolForDirectGrants and return a POOL data", async function () {

      const tx = await testContract.createPoolForDirectGrants(
        profileId,
        directGrantsSimpleStrategy.address,
        "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
        0,
        [1, "test pointer"],
        ["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", testContract.address],
        {gasLimit: 3000000}
      );

      const txReceipt = await tx.wait();

      // poolId = txReceipt.events.pop().topics[1];

      poolId = ethers.BigNumber.from(txReceipt.events.pop().topics[1]);

      console.log("Pool ID:", poolId);

      const testContractBalance = await ethers.provider.getBalance(testContract.address);
      console.log(colors.white(`TestContract balance is ${ethers.utils.formatEther(testContractBalance)} ETH`));

      const fundAmount = ethers.utils.parseEther("1"); // 1 ether, for example
      const fundPoolTx = await testContract.supplyPool(poolId, fundAmount);
      await fundPoolTx.wait();

      console.log(colors.white(" Pool Funding RESULT"))
      console.log(fundPoolTx)
    
      // Check TestContract balance after funding the pool
      const testContractBalanceAfter = await ethers.provider.getBalance(testContract.address);
      console.log(colors.white(`TestContract balance after funding is ${ethers.utils.formatEther(testContractBalanceAfter)} ETH`));



    });

    it("Should successfully call registerRecipient and return a Recipient data", async function () {

      const metadata = {
        protocol: 1,
        pointer: ""
      };

      const tx = await testContract.registerRecipient(
        poolId,  // Assuming poolId is already defined and holds the correct value
        "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",  // recipientAddress
        "0x0000000000000000000000000000000000000000",  // registryAnchor (dummy address for example)
        ethers.utils.parseEther("0.2"),      // grantAmount
        metadata,  // metadata
        { gasLimit: 3000000}
      );
    
      const txReceipt = await tx.wait();

      // console.log("---- Register Recipient")
      // console.log(txReceipt.events)
    
      // Assuming the event's second topic contains the recipient ID
      const recipientId = txReceipt.events.pop().topics[1];
    
      console.log("Recipient ID:", colors.white(recipientId));

      const getRecipienttx = await directGrantsSimpleStrategy.getRecipient(testContract.address);
    
      console.log("---- Get NEW Recipient")
      console.log(getRecipienttx)
    });
    
    it("Should successfully call allocateFundsToRecipient() and emit allocated event", async function () {
    
      const tx = await testContract.allocateFundsToRecipient(
        poolId,
        testContract.address,
        2,
        0,
        { gasLimit: 3000000}
      );

      const txAllocate = await tx.wait();

      console.log("---- txAllocate")
      console.log(txAllocate.events)

      const getRecipientAfterAllocation = await directGrantsSimpleStrategy.getRecipient(testContract.address);
    
      console.log("---- Get Recipient data after Allocation")
      console.log(getRecipientAfterAllocation)
    
    });

    const { ethers } = require("hardhat");

    it("Should successfully call setMilestones()", async function () {

        // Import the account using its private key
        const privateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
        const wallet = new ethers.Wallet(privateKey, ethers.provider);
        const directGrantsSimpleStrategyWithSigner = directGrantsSimpleStrategy.connect(wallet);

        // Define the metadata structure as per your contract requirements
        const metadata = {
          protocol: 1,
          pointer: ""
        };

        // Define milestones array
        const milestones = [
          {
            amountPercentage: ethers.utils.parseUnits("0.5", "ether"), 
            metadata: metadata,
            milestoneStatus: 0
          },
          {
            amountPercentage: ethers.utils.parseUnits("0.5", "ether"), 
            metadata: metadata,
            milestoneStatus: 0
          }
        ];

        // Call the function with the specified account and milestones array
        const setMilestonesTx = await directGrantsSimpleStrategyWithSigner.setMilestones(
          testContract.address,
          milestones,
          { gasLimit: 3000000}
        );

        const setMilestonesTxResult = await setMilestonesTx.wait();

        console.log("---- set Milestones Tx Result");
        console.log(setMilestonesTxResult);
    });


  });
});  
