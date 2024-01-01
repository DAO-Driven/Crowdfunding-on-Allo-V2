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
  let testRecipientPrivateKey = process.env.TEST_RECIPIENT_KEY;

  const supplier_1 = new ethers.Wallet(process.env.TEST_SUPPLIER_1_KEY, ethers.provider);
  const supplier_2 = new ethers.Wallet(process.env.TEST_SUPPLIER_2_KEY, ethers.provider);
  const supplier_3 = new ethers.Wallet(process.env.TEST_SUPPLIER_3_KEY, ethers.provider);
  const supplier_4 = new ethers.Wallet(process.env.TEST_SUPPLIER_4_KEY, ethers.provider);
  const supplier_5 = new ethers.Wallet(process.env.TEST_SUPPLIER_5_KEY, ethers.provider);

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

    const accounts = [supplier_1, supplier_2, supplier_3];

    it("Should successfully call registerProject and return a profile data\n\n", async function () {

      console.log(colors.white("\n\n================== managerContract Functionality test STARTS ==================\n\n")) 


      const tx = await managerContract.registerProject(
        ethers.utils.parseEther("1"),
        77777777, 
        "Dev Profile 1", 
        [1, "test pointer"], 
        testRecipientAddress,
        "Test Description of the project"
      );

      const txReceipt = await tx.wait();
      profileId = txReceipt.events[2].topics[1];

      console.log(colors.white("================== Profile ID:"), profileId) 

      const getProfileById = await managerContract.getProfile(profileId);

      console.log(colors.white("================== GET new Profile by ID:"), getProfileById[0]) 
      console.log(getProfileById);
    });

    it("Should successfully call supplyProject and fund Project\n\n", async function () {

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

      const projectSuppliers = await managerContract.getProjectSuppliers(profileId);

      console.log(colors.white("================== project Suppliers after FUNDING")) 
      console.log(projectSuppliers);

      for (const supplier of accounts){

        const managerContractWithSigner = await managerContract.connect(supplier);
        const supplierAddress = supplier.address;
        const tx = await managerContractWithSigner.getProjectSupplierById(profileId, supplierAddress);
    
        console.log("====> Supplier:", supplierAddress);
        console.log("====> Supply", tx);
      }

    });

    it("Should successfully call revoke Supply delete supplier from the list\n\n", async function () {

      const managerContractWithSigner = await managerContract.connect(supplier_4);
      const supplyAmount = ethers.utils.parseEther("0.15");

      const tx = await managerContractWithSigner.supplyProject(profileId, supplyAmount, { value: supplyAmount });
      await tx.wait();

      const projectSupply = await managerContract.getProjectSupply(profileId);
      console.log(colors.white("================== projectSupply after FUNDING BEFORE REVOKE")) 
      console.log(projectSupply);

      const revokerBalance = await ethers.provider.getBalance(supplier_4.address);
      console.log(colors.white("================== REVOKER balance before revoke:"), revokerBalance); 

      const projectSuppliers = await managerContract.getProjectSuppliers(profileId);
      console.log(colors.white("================== project Suppliers Before the REVOKE")) 
      console.log(projectSuppliers);

      const txRevoke = await managerContractWithSigner.revokeProjectSupply(profileId);
      await txRevoke.wait();

      const projectSupplyAfterRevoke = await managerContract.getProjectSupply(profileId);
      console.log(colors.white("================== projectSupply after REVOKE")) 
      console.log(projectSupplyAfterRevoke);

      const revokerBalanceAfter = await ethers.provider.getBalance(supplier_4.address);
      console.log(colors.white("================== REVOKER balance after revoke:"), revokerBalanceAfter); 

      const projectSuppliersAfterRevoke = await managerContract.getProjectSuppliers(profileId);
      console.log(colors.white("================== project Suppliers AFTER the REVOKE")) 
      console.log(projectSuppliersAfterRevoke);

    })

    it("Should successfully Supply by last Supplier and return POOL's number\n\n", async function () {

      const supplyAmount = ethers.utils.parseEther("0.25");
      const managerContractWithSigner = await managerContract.connect(supplier_5);

      const tx = await managerContractWithSigner.supplyProject(profileId, supplyAmount, {value: supplyAmount, gasLimit: 3000000});
      const poolCreatedResult = await tx.wait();
      const poolData = poolCreatedResult.events.pop().args

      poolId = poolData.poolId
      console.log(colors.white("================== POOL ID:"), poolId);
    });
  })

  // describe(colors.white("= DESCRIBE ================== PROJECT REJECTING =================="), function () {

  //   it("Should successfully rejet Project by voting of suppliers", async function () {

  //     const projetcRejectingAccounts = [supplier_1, supplier_2, supplier_3];

  //     console.log(colors.white("\n\n====> SUPPLIERS BALANCE BEFORE REJECTING"))
  //     for (const account of projetcRejectingAccounts) {

  //       const supplierBalanceBefore = await ethers.provider.getBalance(account.address);
  //       console.log(colors.yellow(`supplier Balance: ${ethers.utils.formatEther(supplierBalanceBefore)} ETH`));
  //     }

  //     for (const account of projetcRejectingAccounts) {

  //       const clonedStrategyAddress = await managerContract.getProjectStrategy(profileId);
  //       const ExecutorSupplierVotingStrategy = await ethers.getContractFactory("ExecutorSupplierVotingStrategy");
  //       const executorSupplierVotingStrategyWithSigner = ExecutorSupplierVotingStrategy.attach(clonedStrategyAddress).connect(account);

  //       const tx = await executorSupplierVotingStrategyWithSigner.rejectProject(
  //         2, 
  //         { gasLimit: 3000000}
  //       );

  //       const rejectProjectTxResult = await tx.wait();
  //       // console.log(colors.white("----> Reject ProjectTxResult Tx Result"));
  //       // console.log(rejectProjectTxResult);
  //     }

  //     console.log(colors.white("\n\n====> SUPPLIERS BALANCE AFTER REJECTING"))
  //     for (const account of projetcRejectingAccounts) {

  //       const supplierBalanceBefore = await ethers.provider.getBalance(account.address);
  //       console.log(colors.yellow(`supplier Balance: ${ethers.utils.formatEther(supplierBalanceBefore)} ETH`));
  //     }
  //   })
  // });


  describe(colors.white("=== DESCRIBE ================== Milestones Offer Functionality =================="), function () {

    it("Should successfully call offerMilestones() and return milestones data", async function () {

      // Import the account using its private key
      const privateKey = testRecipientPrivateKey;
      const wallet = new ethers.Wallet(privateKey, ethers.provider);
      const clonedStrategyAddress = await managerContract.getProjectStrategy(profileId);

      expect(ethers.utils.isAddress(clonedStrategyAddress)).to.be.true;

      const ExecutorSupplierVotingStrategy = await ethers.getContractFactory("ExecutorSupplierVotingStrategy");
      const executorSupplierVotingStrategyWithSigner = await ExecutorSupplierVotingStrategy.attach(clonedStrategyAddress).connect(wallet);

      console.log(colors.white(`Connected to cloned strategy at address: ${clonedStrategyAddress}`));

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
      const clonedStrategyAddress = await managerContract.getProjectStrategy(profileId);

      for (const account of milestonesReviewingaccounts) {

        const ExecutorSupplierVotingStrategy = await ethers.getContractFactory("ExecutorSupplierVotingStrategy");
        const executorSupplierVotingStrategyWithSigner = ExecutorSupplierVotingStrategy.attach(clonedStrategyAddress).connect(account);
  
        const tx = await executorSupplierVotingStrategyWithSigner.reviewOfferedtMilestones(
          testRecipientAddress, 
          2, 
          { gasLimit: 3000000}
        );

        const reviewMilestoneTxResult = await tx.wait();
        // console.log(colors.white("----> review Milestone Tx Result"));
        // console.log(reviewMilestoneTxResult);
      }

      const ExecutorSupplierVotingStrategy = await ethers.getContractFactory("ExecutorSupplierVotingStrategy");
      const executorSupplierVotingStrategyWithSigner = ExecutorSupplierVotingStrategy.attach(clonedStrategyAddress).connect(supplier_1);

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

      const clonedStrategyAddress = await managerContract.getProjectStrategy(profileId);
      const ExecutorSupplierVotingStrategy = await ethers.getContractFactory("ExecutorSupplierVotingStrategy");
      const executorSupplierVotingStrategyWithSigner = ExecutorSupplierVotingStrategy.attach(clonedStrategyAddress).connect(supplier_1);

      const getRecipientAfterAllocation = await executorSupplierVotingStrategyWithSigner.getRecipient(testRecipientAddress);
    
      console.log("---- Get Recipient data after Allocation")
      console.log(getRecipientAfterAllocation)
    });

    it("Should successfully call submitMilestone() and emit MilestoneSubmitted event", async function () {

      const wallet = new ethers.Wallet(testRecipientPrivateKey, ethers.provider);

      const clonedStrategyAddress = await managerContract.getProjectStrategy(profileId);
      const ExecutorSupplierVotingStrategy = await ethers.getContractFactory("ExecutorSupplierVotingStrategy");
      const executorSupplierVotingStrategyWithSigner = ExecutorSupplierVotingStrategy.attach(clonedStrategyAddress).connect(wallet);

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

        const clonedStrategyAddress = await managerContract.getProjectStrategy(profileId);
        const ExecutorSupplierVotingStrategy = await ethers.getContractFactory("ExecutorSupplierVotingStrategy");
        const executorSupplierVotingStrategyWithSigner = ExecutorSupplierVotingStrategy.attach(clonedStrategyAddress).connect(account);

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
      console.log(colors.white(`testRecipient Address Balance After Distribute is ${ethers.utils.formatEther(testRecipientAddressBalanceAfter)} ETH`));
    })

    it("Should successfully call submit LAST Milestone", async function () {

      const wallet = new ethers.Wallet(testRecipientPrivateKey, ethers.provider);
  
      const clonedStrategyAddress = await managerContract.getProjectStrategy(profileId);
      const ExecutorSupplierVotingStrategy = await ethers.getContractFactory("ExecutorSupplierVotingStrategy");
      const executorSupplierVotingStrategyWithSigner = ExecutorSupplierVotingStrategy.attach(clonedStrategyAddress).connect(wallet);
  
      const metadata = {
        protocol: 1,
        pointer: ""
      };
  
      const submitMilestonesTx = await executorSupplierVotingStrategyWithSigner.submitMilestone(
        testRecipientAddress,
        1,
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

    it("Should successfully call review LAST Submited Milestone by all suppliers and distribut accepted milestone", async function () {

      const testRecipientAddressBalanceBefore = await ethers.provider.getBalance(testRecipientAddress);
      console.log(colors.white(`testRecipient Address Balance Before Distribute is ${ethers.utils.formatEther(testRecipientAddressBalanceBefore)} ETH`));

      const milestoneReviewingaccounts = [supplier_1, supplier_2, supplier_3];
  
      for (const account of milestoneReviewingaccounts) {

        const clonedStrategyAddress = await managerContract.getProjectStrategy(profileId);
        const ExecutorSupplierVotingStrategy = await ethers.getContractFactory("ExecutorSupplierVotingStrategy");
        const executorSupplierVotingStrategyWithSigner = ExecutorSupplierVotingStrategy.attach(clonedStrategyAddress).connect(account);

        const tx = await executorSupplierVotingStrategyWithSigner.reviewSubmitedMilestone(
          testRecipientAddress, 
          1,
          2, 
          { gasLimit: 3000000}
        );

        const reviewMilestoneTxResult = await tx.wait();
        // console.log(colors.white("----> review Milestone Tx Result"));
        // console.log(reviewMilestoneTxResult.events);
      }

      const testRecipientAddressBalanceAfter = await ethers.provider.getBalance(testRecipientAddress);
      console.log(colors.white(`testRecipient Address Balance After Distribute is ${ethers.utils.formatEther(testRecipientAddressBalanceAfter)} ETH`));
    })
  });


  describe(colors.white(" DESCRIBE ================== SEND TOKENS OF THANKS =================="), function () {

    it("Should successfully call sendTokenOfThanksToSuppliers and distribute the tokens between the suppliers", async function () {


      const projetcRejectingAccounts = [supplier_1, supplier_2, supplier_3];

      console.log(colors.white("\n\n====> SUPPLIERS BALANCES BEFORE"))
      for (const account of projetcRejectingAccounts) {

        const supplierBalanceBefore = await ethers.provider.getBalance(account.address);
        console.log(colors.yellow(`supplier Balance: ${ethers.utils.formatEther(supplierBalanceBefore)} ETH`));
      }

      const privateKey = testRecipientPrivateKey;
      const wallet = new ethers.Wallet(privateKey, ethers.provider);

      const clonedStrategyAddress = await managerContract.getProjectStrategy(profileId);
      const ExecutorSupplierVotingStrategy = await ethers.getContractFactory("ExecutorSupplierVotingStrategy");
      const executorSupplierVotingStrategyWithSigner = ExecutorSupplierVotingStrategy.attach(clonedStrategyAddress).connect(wallet);


      const supplyAmount = ethers.utils.parseEther("0.25");

      const sendThankstoSuppliersTx = await executorSupplierVotingStrategyWithSigner.sendTokenOfThanksToSuppliers(
        supplyAmount,
        {value: supplyAmount, gasLimit: 3000000}
      );

      const result = await sendThankstoSuppliersTx.wait();

      // console.log(colors.white("\n\n====> sendTokenOfThanksToSuppliers RESULT"))
      // console.log(result)


      console.log(colors.white("\n\n====> SUPPLIERS BALANCE AFTER REJECTING"))
      for (const account of projetcRejectingAccounts) {

        const supplierBalanceBefore = await ethers.provider.getBalance(account.address);
        console.log(colors.yellow(`supplier Balance: ${ethers.utils.formatEther(supplierBalanceBefore)} ETH`));
      }

    })
  })
});  
