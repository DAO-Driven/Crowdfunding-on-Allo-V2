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


  const supplier_1 = new ethers.Wallet("0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a", ethers.provider);
  const supplier_2 = new ethers.Wallet("0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba", ethers.provider);
  const supplier_3 = new ethers.Wallet("0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e", ethers.provider);

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

    const accounts = [supplier_1, supplier_2, supplier_3];

    it("Should successfully call registerProject and return a profile data\n\n", async function () {

      console.log(colors.white("\n\n================== managerContract Functionality test STARTS ==================\n\n")) 


      const tx = await managerContract.registerProject(
        ethers.utils.parseEther("1"),
        77777777, 
        "Dev Profile 1", 
        [1, "test pointer"], 
        managerContract.address, 
        testRecipientAddress
      );

      const txReceipt = await tx.wait();
      profileId = txReceipt.events[2].topics[1];

      console.log(colors.white("================== Profile ID:"), profileId) 

      const getProfileById = await managerContract.getProfile(profileId);

      console.log(colors.white("================== GET new Profile by ID:"), getProfileById[0]) 
      console.log(getProfileById);

      const getAllProfiles = await managerContract.getProfiles();

      console.log(colors.white("================== GET All Profiles")) 
      console.log(getAllProfiles);
    });

    it("Should successfully call supplyProject and fund Project \n\n", async function () {

      const supplyAmount = ethers.utils.parseEther("0.25");

      for (const account of accounts) {
        // Connect the managerContract to the current account (signer)
        const managerContractWithSigner = await managerContract.connect(account);

        // Now call supplyProject with the connected contract instance
        const tx = await managerContractWithSigner.supplyProject(profileId, supplyAmount, { value: supplyAmount });
        await tx.wait();
      }

      const projectSupply = await managerContract.getProjectSupply(profileId);

      console.log(colors.white("================== projectSupply after FUNDING")) 
      console.log(projectSupply);

    });

    // it("Should successfully call revoke Supply and dont let to supply again \n\n", async function () {

    //   const supplier_4 = new ethers.Wallet("0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356", ethers.provider);
    //   const managerContractWithSigner = await managerContract.connect(supplier_4);

    //   const supplyAmount = ethers.utils.parseEther("0.15");

    //   const tx = await managerContractWithSigner.supplyProject(profileId, supplyAmount, { value: supplyAmount });
    //   await tx.wait();

    //   const projectSupply = await managerContract.getProjectSupply(profileId);
    //   console.log(colors.white("================== projectSupply after FUNDING BEFORE REVOKE")) 
    //   console.log(projectSupply);

    //   const revokerBalance = await ethers.provider.getBalance(supplier_4.address);
    //   console.log(colors.white("================== REVOKER balance before revoke:"), revokerBalance); 

    //   const txRevoke = await managerContractWithSigner.revokeProjectSupply(profileId);
    //   await txRevoke.wait();

    //   const projectSupplyAfterRevoke = await managerContract.getProjectSupply(profileId);
    //   console.log(colors.white("================== projectSupply after REVOKE")) 
    //   console.log(projectSupplyAfterRevoke);

    //   const revokerBalanceAfter = await ethers.provider.getBalance(supplier_4.address);

    //   console.log(colors.white("================== REVOKER balance after revoke:"), revokerBalanceAfter); 


    //   const txSupplyAGAIN = await managerContractWithSigner.supplyProject(profileId, supplyAmount, { value: supplyAmount, gasLimit: 3000000});
    //   await txSupplyAGAIN.wait();

    //   console.log(colors.white("================== SUPPLY AGAIN")) 
    //   console.log(txSupplyAGAIN);
    // })

    it("Should successfully Supply by last Supplier \n\n", async function () {

      const supplier_5 = new ethers.Wallet("0xa267530f49f8280200edf313ee7af6b827f2a8bce2897751d06a843f644967b1", ethers.provider);
      const supplyAmount = ethers.utils.parseEther("0.25");

      const managerContractWithSigner = await managerContract.connect(supplier_5);

      const tx = await managerContractWithSigner.supplyProject(profileId, supplyAmount, {value: supplyAmount, gasLimit: 3000000});
      const poolCreatedResult = await tx.wait();
      const poolData = poolCreatedResult.events.pop().args

      poolId = poolData.poolId
      console.log(colors.white("================== POOL ID:"), poolId);
    });
  })

  describe(colors.white("= DESCRIBE ================== Milestones Offer Functionality =================="), function () {

    it("Should successfully call offerMilestones() and return milestones data", async function () {

      // Import the account using its private key
      const privateKey = testRecipientPrivateKey;
      const wallet = new ethers.Wallet(privateKey, ethers.provider);
      const executorSupplierVotingStrategyWithSigner = executorSupplierVotingStrategy.connect(wallet);

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
          milestoneStatus: 0,
          description: "i will do my best"
        },
        {
          amountPercentage: ethers.utils.parseUnits("0.5", "ether"), 
          metadata: metadata,
          milestoneStatus: 0,
          description: "i will do my best"
        }
      ];

      // Call the function with the specified account and milestones array
      const setMilestonesTx = await executorSupplierVotingStrategyWithSigner.offerMilestones(
        testRecipientAddress,
        milestones,
        { gasLimit: 3000000}
      );

      const setMilestonesTxResult = await setMilestonesTx.wait();

      // console.log("---- Offer Milestones Tx Result");
      // console.log(setMilestonesTxResult.events);


      const getMilestonesTx = await executorSupplierVotingStrategyWithSigner.getOffeeredMilestones(
        testRecipientAddress,
        { gasLimit: 3000000}
      );

      console.log(colors.white("---- GET Offered Milestones"));
      console.log(getMilestonesTx);
    });

    it("Should successfully call reviewOfferedtMilestones() and return milestones data", async function () {  
  
      const milestonesReviewingaccounts = [supplier_1, supplier_2, supplier_3];
  
      for (const account of milestonesReviewingaccounts) {
        // Connect the managerContract to the current account (signer)
        const executorSupplierVotingStrategyWithSigner = executorSupplierVotingStrategy.connect(account);
  
        const tx = await executorSupplierVotingStrategyWithSigner.reviewOfferedtMilestones(testRecipientAddress, 2, { gasLimit: 3000000});
        const reviewMilestoneTxResult = await tx.wait();
        // console.log(colors.white("----> review Milestone Tx Result"));
        // console.log(reviewMilestoneTxResult);
      }

      const executorSupplierVotingStrategyWithSigner = executorSupplierVotingStrategy.connect(supplier_1);

      const getMilestonesTx = await executorSupplierVotingStrategyWithSigner.getMilestones(
        testRecipientAddress,
        { gasLimit: 3000000}
      );

      console.log(colors.white("---- GET Recipient Milestones"));
      console.log(getMilestonesTx);
    });
  });

  describe(colors.white("= DESCRIBE ================== Milestones Submissions Functionality =================="), function () {

    it("Should successfully get test recipient and show its data ", async function () {
    
      // OLD LOGIC! .... Currently, the funds are being allocated by the strategy in the _setMilestones function/method.
      // At the moment this block is only to see recipient data

      // const tx = await managerContract.allocateFundsToRecipient(
      //   poolId,
      //   testRecipientAddress,
      //   2,
      //   ethers.utils.parseEther("1"),
      //   { gasLimit: 3000000}
      // );

      // const txAllocate = await tx.wait();

      // console.log("---- txAllocate")
      // console.log(txAllocate)

      const getRecipientAfterAllocation = await executorSupplierVotingStrategy.getRecipient(testRecipientAddress);
    
      console.log("---- Get Recipient data after Allocation")
      console.log(getRecipientAfterAllocation)
    
    });

    it("Should successfully call submitMilestone() and emit MilestoneSubmitted event", async function () {

      const wallet = new ethers.Wallet(testRecipientPrivateKey, ethers.provider);
      const executorSupplierVotingStrategyWithSigner = executorSupplierVotingStrategy.connect(wallet);

      const metadata = {
        protocol: 1,
        pointer: ""
      };

      const submitMilestonesTx = await executorSupplierVotingStrategyWithSigner.submitMilestone(
        testRecipientAddress,
        0,
        metadata,
        { gasLimit: 3000000}
      );

      const submitMilestonesTxResult = await submitMilestonesTx.wait();
      // console.log(colors.white("---- submitMilestones Tx Result"));
      // console.log(submitMilestonesTxResult.events);

      const getMilestonesTx = await executorSupplierVotingStrategyWithSigner.getMilestones(
        testRecipientAddress,
        { gasLimit: 3000000}
      );

      console.log(colors.white("=======> testRecipient's milestones:"));
      console.log(getMilestonesTx);
    });

    it("Should successfully call reviewSubmitedMilestone() by all suppliers and distribut accepted milestone", async function () {


      const testRecipientAddressBalanceBefore = await ethers.provider.getBalance(testRecipientAddress);

      console.log(colors.white(`testRecipient Address Balance Before Distribute is ${ethers.utils.formatEther(testRecipientAddressBalanceBefore)} ETH`));

      const milestoneReviewingaccounts = [supplier_1, supplier_2, supplier_3];
  
      for (const account of milestoneReviewingaccounts) {

        const executorSupplierVotingStrategyWithSigner = executorSupplierVotingStrategy.connect(account);
  
        const tx = await executorSupplierVotingStrategyWithSigner.reviewSubmitedMilestone(
          testRecipientAddress, 
          0,
          2, 
          { gasLimit: 3000000}
        );

        const reviewMilestoneTxResult = await tx.wait();
        // console.log(colors.white("----> review Milestone Tx Result"));
        // console.log(reviewMilestoneTxResult.events);
      }

      const testRecipientAddressBalanceAfter = await ethers.provider.getBalance(testRecipientAddress);

      console.log(colors.white(`testRecipient Address Balance Before Distribute is ${ethers.utils.formatEther(testRecipientAddressBalanceAfter)} ETH`));
    })
  });
});  
