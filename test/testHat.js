require('dotenv').config();
const { expect } = require("chai");
const { ethers } = require("hardhat");
const colors = require('colors');
const hatsAbi = require('./hats/hatAbi.json');

const mainHatKey = process.env.TOP_HAT_PRIVATE_KEY;


describe("Contract Deployment", function () {
    
    const mainHAT = new ethers.Wallet(mainHatKey, ethers.provider);
    const hatsAddress = "0x3bc1A0Ad72417f2d411118085256fC53CBdDd137";    
    const hatID = "10514379611564888850221646422679951602056112570474789676025373834346496";

    let SupplierHatID = "";

    const supplier_1 = new ethers.Wallet("0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a", ethers.provider);

    before(async function () {
        // Setup code, if any
    });

    it("Should fund mainHat ", async function () {
        const fundAmount = ethers.utils.parseEther("1");

        const testRecipientAddressBalanceBefore = await ethers.provider.getBalance("0x01Ae8d6d0F137CF946e354eA707B698E8CaE6485");

        console.log(colors.white(`testRecipient Address Balance Before is ${ethers.utils.formatEther(testRecipientAddressBalanceBefore)} ETH`));

        const fundTx = await supplier_1.sendTransaction({
            to: "0x01Ae8d6d0F137CF946e354eA707B698E8CaE6485",
            value: fundAmount,
            gasLimit: 3000000
        });

        const fundResult = await fundTx.wait();
      
        // console.log(colors.white(`Funded with ${fundAmount.toString()} wei`));
        // console.log(fundResult);

        const testRecipientAddressBalanceAfter = await ethers.provider.getBalance("0x01Ae8d6d0F137CF946e354eA707B698E8CaE6485");

        console.log(colors.white(`testRecipient Address Balance After is ${ethers.utils.formatEther(testRecipientAddressBalanceAfter)} ETH`));
    });

    it("Should check if mainHAT is admin of the specified hat", async function () {
        // Connect to the Hats contract with mainHAT
        const hatsContract = await ethers.getContractAt(
            hatsAbi, 
            hatsAddress, 
            mainHAT
        );
    
        // Specify the hat ID to check
        const hatIdToCheck = hatID; 
    
        // Call the isAdminOfHat function
        const isAdmin = await hatsContract.isAdminOfHat(
            mainHAT.address, // Address to check
            hatIdToCheck      // Hat ID
        );
    
        // Output the result to the console
        console.log(`Is mainHAT admin of Hat ID ${hatIdToCheck}:`, isAdmin);

        const isActive = await hatsContract.isActive(
            hatIdToCheck      // Hat ID
        );

        console.log(`Is Hat ACTIVE ${hatIdToCheck}:`, isActive);

    });

    it("Should transfer the hat to supplier_1", async function () {
        const hatsContract = await ethers.getContractAt(
            hatsAbi, 
            hatsAddress, 
            mainHAT
        );
    
        const hatId = hatID;
        const supplier1Address = supplier_1.address;
    
        // Check if supplier_1 is eligible
        const isEligible = await hatsContract.isEligible(supplier1Address, hatId);
        console.log(`Is supplier_1 eligible for Hat ID ${hatId}:`, isEligible);

        const isMainHatWearing = await hatsContract.isWearerOfHat(mainHAT.address, hatId);
        console.log(`Is mainHAT wearing Hat ID ${hatId}:`, isMainHatWearing);

    
        if (isEligible) {
            try {
                // Attempt to transfer the hat
                await hatsContract.transferHat(
                    hatId, 
                    mainHAT.address, 
                    supplier1Address,
                    { gasLimit: 3000000}
                );
                console.log(`Successfully transferred Hat ID ${hatId} to supplier_1`);
            } catch (error) {
                console.error(`Error during transfer of Hat ID ${hatId}:`, error);
            }
        } else {
            console.log(`supplier_1 is not eligible to wear Hat ID ${hatId}`);
        }
    });


    it("Should create a new hat under the transferred hat", async function () {
        // Connect to the Hats contract with supplier_1
        const hatsContract = await ethers.getContractAt(
            hatsAbi, 
            hatsAddress, 
            supplier_1
        );
    
        // Define the new hat's parameters
        const adminHatId = "10514379611564888850221646422679951602056112570474789676025373834346496"; // The transferred hat ID
        const details = "New Hat Description";
        const maxSupply = 10; // Maximum number of these hats
        const eligibility = supplier_1.address; // Address of the eligibility module
        const toggle = supplier_1.address; // Address of the toggle module
        const mutable = true; // Whether the hat's properties can be changed
        const imageURI = "http://example.com/new-hat-image.jpg"; // URI of the hat image
    
        try {
            // Call the createHat function to create the new hat
            const createHatTx = await hatsContract.createHat(
                adminHatId,
                details,
                maxSupply,
                eligibility,
                toggle,
                mutable,
                imageURI
            );
    
            const receipt = await createHatTx.wait();

            console.log(colors.white("=======> New HAT RESULT <======="))
            console.log(receipt)

            if (receipt.events){

                console.log(colors.white("=======> New HAT EVENTS <======="))
                console.log(receipt.events[0].args);

                const newHatEvent = receipt.events.find(event => event.event === 'HatCreated');

                const newHatId = newHatEvent.args.id;

                SupplierHatID = newHatId;

                console.log(`New hat created with ID: ${newHatId}`);
            }            
        } catch (error) {
            console.error(`Error during creation of new hat:`, error);
        }
    });    

    describe("Minting New Hat to Wearers", function () {
        
        it("Should mint the new hat to a wearer", async function () {

            const hatsContract = await ethers.getContractAt(
                hatsAbi, 
                hatsAddress, 
                supplier_1
            );
    
            const wearerAddress = "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199";
            
            try {
                const mintTx = await hatsContract.mintHat(SupplierHatID, wearerAddress);
                await mintTx.wait();

                console.log(`Hat ID ${SupplierHatID} minted to wearer at ${wearerAddress}`);
            } catch (error) {
                console.error("Minting failed:", error);
            }

            const isMainHatWearing = await hatsContract.isWearerOfHat(wearerAddress, SupplierHatID);
            console.log(`Is wearing Supplier Hat:`, isMainHatWearing);
        });
    
        // Additional tests for other wearers...
    });
    

    // Other tests...
});