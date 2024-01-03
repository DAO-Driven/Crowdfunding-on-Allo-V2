const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const STRATEGY_NAME = "Executor-Supplier-Voting";
    const ALLO_V2_ADDRESS = "0x1133eA7Af70876e64665ecD07C0A0476d09465a1";
    const HATS_ADDRESS = "0x3bc1A0Ad72417f2d411118085256fC53CBdDd137";    
    const MANAGER_HAT_ID = process.env.MANAGER_HAT_ID;

    const ExecutorSupplierVotingStrategy = await hre.ethers.getContractFactory("ExecutorSupplierVotingStrategy");
    const executorSupplierVotingStrategy = await ExecutorSupplierVotingStrategy.deploy(ALLO_V2_ADDRESS, STRATEGY_NAME);
    await executorSupplierVotingStrategy.deployed();
    console.log("ExecutorSupplierVotingStrategy deployed to:", executorSupplierVotingStrategy.address);

    const StrategyFactory = await ethers.getContractFactory("StrategyFactory");
    const strategyFactory = await StrategyFactory.deploy();
    await strategyFactory.deployed();
    console.log("strategyFactory deployed to:", strategyFactory.address);

    const Manager = await hre.ethers.getContractFactory("Manager");
    const manager = await Manager.deploy(
        ALLO_V2_ADDRESS, 
        executorSupplierVotingStrategy.address, 
        strategyFactory.address,
        HATS_ADDRESS,
        MANAGER_HAT_ID
    );
    await manager.deployed();
    console.log("Manager deployed to:", manager.address);

    // ExecutorSupplierVotingStrategy deployed to: 0x802fEC80ee397F15FE7E409d1F1d70B4B6e3241c
    // strategyFactory deployed to: 0x78cf00AEadbCB04300AE24910e5b67D4fc6cCD02
    // Manager deployed to: 0xe9E81a25829810c1BF1e6082E5EA0C65BE140462
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
