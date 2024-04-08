// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAllo} from "./interfaces/IAllo.sol";
import {IStrategyFactory} from "./interfaces/IStrategyFactory.sol";
import {IHats} from "./interfaces/Hats/IHats.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IRegistry.sol";


contract Manager is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    /// @notice Enum representing various statuses a project or milestone can have.
    enum Status {
        None,       // Default state, indicating no status.
        Pending,    // Indicates awaiting a decision or action.
        Accepted,   // Indicates approval or acceptance.
        Rejected,   // Indicates disapproval or rejection.
        Appealed,   // Indicates an appeal to a decision.
        InReview,   // Indicates currently under review.
        Canceled    // Indicates cancellation.
    }

    /// @notice Struct to hold initialization data for setting up a project or strategy.
    struct InitializeData {
        uint256 supplierHat;          // ID of the Supplier Hat.
        uint256 executorHat;          // ID of the Executor Hat.
        SupplierPower[] supliersPower; // Array of SupplierPower, representing the power of each supplier.
        address hatsContractAddress;  // Address of the Hats contract.
        uint8 thresholdPercentage;
    }

    /// @notice Struct representing the supply details of a project.
    struct ProjectSupply {
        uint256 need;                 // The total amount needed for the project.
        uint256 has;                  // The amount currently supplied.         // Description of the project.
    }

    /// @notice Struct for mapping suppliers to their supply amount by ID.
    struct SuppliersById {
        mapping(address => uint256) supplyById; // Maps supplier address to their supply amount.
    }

    /// @notice Struct representing the power or influence of a supplier.
    struct SupplierPower {
        address supplierId;           // Address of the supplier.
        uint256 supplierPowerr;       // Power value associated with the supplier.
    }

    /// @notice Struct holding IDs for different types of hats used in the system.
    struct Hats {
        uint256 executorHat;          // ID of the Executor Hat.
        uint256 supplierHat;          // ID of the Supplier Hat.
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// @notice Reverts if the project is already fully funded and does not require additional supply.
    error PROJECT_IS_FUNDED();

    /// @notice Reverts if the amount is greater than the project's declared needed amount.
    error AMOUNT_IS_BIGGER_THAN_DECLARED_NEEDEDS();

    /// @notice Reverts if an executor attempts to supply, which is not permitted.
    error EXECUTOR_IS_NOT_ALLOWED_TO_SUPPLY();

    /// @notice Thrown when not enough funds are available
    error NOT_ENOUGH_FUNDS();

    /// @notice Interface to interact with the Registry contract.
    IRegistry registry;

    /// @notice Interface to interact with the Allo contract.
    IAllo allo;

    /// @notice Address of the strategy contract.
    address strategy;

    /// @notice Interface to interact with the Strategy Factory contract.
    IStrategyFactory strategyFactory;

    /// @notice Interface to interact with the Hats contract.
    IHats public hatsContract;

    /// @notice ID of the manager's hat in the Hats contract.
    uint256 managerHatID;

    /// @notice Address of the Hats contract.
    address hatsContractAddress;

    /// @notice Voting Threshold Percentage.
    uint8 thresholdPercentage;

    address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Array storing the profiles of projects.
    bytes32[] profiles;

    /// @notice Mapping from project ID to an array of supplier addresses for each project.
    mapping(bytes32 => address[]) projectSuppliers;

    /// @notice Mapping from project ID to a struct containing supplier IDs and their supply amounts.
    mapping(bytes32 => SuppliersById) projectSuppliersById;

    /// @notice Mapping from project ID to its supply details, including needs and current supply.
    mapping(bytes32 => ProjectSupply) projectSupply;

    /// @notice Mapping from project ID to the address of its executor.
    mapping(bytes32 => address) projectExecutor;

    /// @notice Mapping from project ID to its associated pool ID.
    mapping(bytes32 => uint256) projectPool;

    /// @notice Mapping from project ID to the address of its strategy contract.
    mapping(bytes32 => address) projectStrategy;

    /// @notice Mapping from project ID to its associated hats (executor and supplier hats).
    mapping(bytes32 => Hats) projectHats;

    bool private initialized;


    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when a project receives funding.
    /// @param projectId The ID of the project that was funded.
    /// @param amount The amount of funds the project received.
    event ProjectFunded(bytes32 indexed projectId, uint256 amount);

    /// @notice Emitted when a pool is created for a project.
    /// @param projectId The ID of the project for which the pool was created.
    /// @param poolId The ID of the newly created pool.
    event ProjectPoolCreeated(bytes32 projectId, uint256 poolId);

    event ProjectRegistered(bytes32 profileId, uint256 nonce);

    event ProjectNeedsUpdated(bytes32 indexed projectId, uint256 newNeeds);


    function initialize(
        address _alloAddress, 
        address _strategy, 
        address _strategyFactory, 
        address _hatsContractAddress, 
        uint256 _managerHatID
    ) public initializer {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;

        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        allo = IAllo(_alloAddress);
        strategy = _strategy;
        strategyFactory = IStrategyFactory(_strategyFactory);
        hatsContractAddress = _hatsContractAddress;
        hatsContract = IHats(_hatsContractAddress);
        managerHatID = _managerHatID;
        address registryAddress = address(allo.getRegistry());
        registry = IRegistry(registryAddress);
        thresholdPercentage = 70; // Default value, adjust as needed
    }


    /// @notice Retrieves the profile of a project from the registry.
    /// @param _projectId The ID of the project.
    /// @return IRegistry.Profile The profile of the specified project.
    function getProfile(bytes32 _projectId) public view returns (IRegistry.Profile memory) {
        return registry.getProfileById(_projectId);
    }

    /// @notice Retrieves the pool ID associated with a project.
    /// @param _projectId The ID of the project.
    /// @return uint256 The pool ID of the specified project.
    function getProjectPool(bytes32 _projectId) public view returns (uint256) {
        return projectPool[_projectId];
    }

    /// @notice Retrieves a list of supplier addresses for a project.
    /// @param _projectId The ID of the project.
    /// @return address[] An array of addresses of the suppliers for the specified project.
    function getProjectSuppliers(bytes32 _projectId) public view returns (address[] memory) {
        return projectSuppliers[_projectId];
    }

    /// @notice Retrieves the supply amount provided by a specific supplier for a project.
    /// @param _projectId The ID of the project.
    /// @param _supplier The address of the supplier.
    /// @return uint256 The amount supplied by the specified supplier for the project.
    function getProjectSupplierById(bytes32 _projectId, address _supplier) public view returns (uint256) {
        return projectSuppliersById[_projectId].supplyById[_supplier];
    }

    /// @notice Retrieves the executor address for a project.
    /// @param _projectId The ID of the project.
    /// @return address The address of the executor for the specified project.
    function getProjectExecutor(bytes32 _projectId) public view returns (address) {
        return projectExecutor[_projectId];
    }

    /// @notice Retrieves the strategy address for a project.
    /// @param _projectId The ID of the project.
    /// @return address The address of the strategy associated with the specified project.
    function getProjectStrategy(bytes32 _projectId) public view returns (address) {
        return projectStrategy[_projectId];
    }

    /**
     * @notice Retrieves the supply details of a specific project.
     * @param _projectId The ID of the project for which to get the supply details.
     * @return ProjectSupply A struct containing the project's supply details, including total need and amount supplied.
    */
    function getProjectSupply(bytes32 _projectId) public view returns (ProjectSupply memory) {
        return projectSupply[_projectId];
    }

    /// @notice Sets a new Allo contract address
    /// @dev Only callable by the contract owner
    /// @param newAlloAddress The address of the new Allo contract
    function setAlloAddress(address newAlloAddress) external onlyOwner {
        allo = IAllo(newAlloAddress);
    }

    /// @notice Sets a new Strategy contract address
    /// @dev Only callable by the contract owner
    /// @param newStrategy The address of the new Strategy contract
    function setStrategyAddress(address newStrategy) external onlyOwner {
        strategy = newStrategy;
    }

    /// @notice Sets a new Strategy Factory contract address
    /// @dev Only callable by the contract owner
    /// @param newStrategyFactory The address of the new Strategy Factory contract
    function setStrategyFactoryAddress(address newStrategyFactory) external onlyOwner {
        strategyFactory = IStrategyFactory(newStrategyFactory);
    }

    /// @notice Sets a new Hats contract address
    /// @dev Only callable by the contract owner
    /// @param newHatsContractAddress The address of the new Hats contract
    function setHatsContractAddress(address newHatsContractAddress) external onlyOwner {
        hatsContractAddress = newHatsContractAddress;
        hatsContract = IHats(newHatsContractAddress);
    }

    /// @notice Sets a new Manager Hat ID
    /// @dev Only callable by the contract owner
    /// @param newManagerHatID The new Manager Hat ID
    function setManagerHatID(uint256 newManagerHatID) external onlyOwner {
        managerHatID = newManagerHatID;
    }

    /// @notice Sets the threshold percentage for a specific profile.
    /// @param _newPercentage The new threshold percentage to be set.
    /// @dev Requires the sender to be the owner of the profile and the percentage to be between 1 and 100.
    function setThresholdPercentage(uint8 _newPercentage)  external onlyOwner {
        require(_newPercentage > 0, "Percentage must be greater than zero");
        require(_newPercentage <= 100, "Invalid percentage");
        thresholdPercentage = _newPercentage;
    }

    /// @notice Registers a new project and creates its profile.
    /// @dev Creates a new project profile in the registry and initializes its supply details.
    /// @param _needs The total amount needed for the project.
    /// @param _nonce A unique nonce for profile creation to ensure uniqueness.
    /// @param _name The name of the project.
    /// @param _metadata Metadata associated with the project.
    /// @param _recipient The address of the project's recipient or executor.
    function registerProject(
        uint256 _needs,
        uint256 _nonce,
        string memory _name,
        Metadata memory _metadata,
        address _recipient
    ) external {
        address[] memory members = new address[](2);
        members[0] = _recipient;
        members[1] = address(this);

        bytes32 profileId = registry.createProfile(_nonce, _name, _metadata, address(this), members);
        projectSupply[profileId].need += allo.getPercentFee() + _needs;
        projectExecutor[profileId] = _recipient;

        profiles.push(profileId);

        emit ProjectRegistered(profileId, _nonce);
    }


    /// @notice Retrieves all registered project profiles.
    /// @return bytes32[] An array of project profile IDs.
    function getProfiles() public view returns (bytes32[] memory){
        return profiles;
    }

    /**
     * @notice Updates the funding requirements ('needs') for a specific project.
     * @dev Requires that the caller is the project executor, the new needs value is greater than the current supply to ensure 
     *      project requirements are realistic, and that the new needs value accounts for necessary fees.
     *      This function is intended to adjust the project's funding target based on revised estimates or project scope changes.
     * @param _projectId The ID of the project for which to update funding requirements.
     * @param _needs The new funding requirement (needs) value for the project.
     */
    function updateProjectNeeds(bytes32 _projectId, uint256 _needs) external {
        require(projectExecutor[_projectId] == msg.sender, "UNAUTHORIZED: Caller must be project executor.");
        require(_needs > projectSupply[_projectId].has, "INVALID VALUE: Needs must exceed current supply.");
        require(_needs > allo.getPercentFee(), "LESS THAN FEE: Needs must be greater than the fee.");
        
        projectSupply[_projectId].need = _needs;

        emit ProjectNeedsUpdated(_projectId, _needs);
    }

    /**
     * @notice Supplies funds to a specific project.
     * @dev This function requires that the project exists and is not fully funded. 
     *      The supplied amount must be non-zero and equal to the sent value. If the supplied amount meets or exceeds 
     *      the project's need, it triggers the creation of supplier and executor hats, and initializes a new pool 
     *      with a custom strategy. Emits a ProjectFunded event and, if funding is complete, a ProjectPoolCreeated event.
     * @param _projectId The ID of the project to supply funds to.
     * @param _amount The amount of funds to supply.
    */
    function supplyProject(bytes32 _projectId, uint256 _amount) external payable nonReentrant {

        if ((projectSupply[_projectId].has + _amount) > projectSupply[_projectId].need){
            revert AMOUNT_IS_BIGGER_THAN_DECLARED_NEEDEDS();
        }
        require(_projectExists(_projectId), "Project does not exist");

        if (_amount == 0 || _amount != msg.value) revert NOT_ENOUGH_FUNDS();

        if (projectPool[_projectId] != 0) revert PROJECT_IS_FUNDED();

        if (projectExecutor[_projectId] == msg.sender) revert EXECUTOR_IS_NOT_ALLOWED_TO_SUPPLY();

        projectSupply[_projectId].has += _amount;

        if (projectSuppliersById[_projectId].supplyById[msg.sender] == 0){
            projectSuppliers[_projectId].push(msg.sender);
        }

        projectSuppliersById[_projectId].supplyById[msg.sender] += _amount;

        emit ProjectFunded(_projectId, _amount);

        if (projectSupply[_projectId].has >= projectSupply[_projectId].need){

            SupplierPower[] memory suppliers = _extractSupliers(_projectId);
            address[] memory managers = new address[](suppliers.length + 1);

            for (uint i = 0; i < suppliers.length; i++) {
                managers[i] = (suppliers[i].supplierId);
            }

            managers[suppliers.length] = address(this);

            _createAndMintHat(
                "Manager", 
                managers, 
                "ipfs://bafkreiey2a5jtqvjl4ehk3jx7fh7edsjqmql6vqxdh47znsleetug44umy/",
                _projectId,
                true
            );

            address[] memory executorAddresses = new address[](1);
            executorAddresses[0] = projectExecutor[_projectId];

            _createAndMintHat(
                "Recipient", 
                executorAddresses, 
                "ipfs://bafkreih7hjg4ehf4lqdoqstlkjxvjy7zfnza4keh2knohsle3ikjja3g2i/",
                _projectId,
                false
            );

            bytes memory encodedInitData = abi.encode(InitializeData({
                supplierHat: projectHats[_projectId].supplierHat,
                executorHat: projectHats[_projectId].executorHat,
                supliersPower: suppliers,
                hatsContractAddress: hatsContractAddress,
                thresholdPercentage: thresholdPercentage
            }));

            projectStrategy[_projectId] = strategyFactory.createStrategy(strategy);

            uint256 pool = allo.createPoolWithCustomStrategy(
                _projectId,
                projectStrategy[_projectId],
                encodedInitData,
                NATIVE,
                0,
                Metadata({
                    protocol: 1,
                    pointer: "https://github.com/alexandr-masl/web3-crowdfunding-on-allo-V2/blob/main/contracts/ExecutorSupplierVotingStrategy.sol"
                }),
                managers
            );

            require(address(this).balance >= projectSupply[_projectId].need, "Insufficient balance in contract");

            allo.fundPool{value: projectSupply[_projectId].need}(pool, projectSupply[_projectId].need);

            bytes memory encodedRecipientParams = abi.encode(
                projectExecutor[_projectId],
                0x0000000000000000000000000000000000000000,
                projectSupply[_projectId].need,
                Metadata({
                    protocol: 1,
                    pointer: "executor"
                })
            );

            allo.registerRecipient(pool, encodedRecipientParams);
            projectPool[_projectId] = pool;

            emit ProjectPoolCreeated( _projectId, pool);
        }
    }

    /**
     * @notice Revokes the supply contributed by the sender to a specific project.
     * @dev Requires that the project exists and the sender has previously supplied funds to it.
     *      The function updates the project's supply details and removes the sender from the list of suppliers.
     *      It also refunds the contributed amount to the sender.
     * @param _projectId The ID of the project from which to revoke the supply.
    */
    function revokeProjectSupply(bytes32 _projectId) external nonReentrant {
        require(_projectExists(_projectId), "Project does not exist");
        
        if (projectPool[_projectId] != 0) revert PROJECT_IS_FUNDED();

        uint256 amount = projectSuppliersById[_projectId].supplyById[msg.sender];
        require(amount > 0, "SUPPLY NOT FOUND");

        delete projectSuppliersById[_projectId].supplyById[msg.sender];

        projectSupply[_projectId].has -= amount;

        address[] memory updatedSuppliers = new address[](projectSuppliers[_projectId].length - 1);
        uint j = 0;

        for (uint i = 0; i < projectSuppliers[_projectId].length; i++) {
            if (projectSuppliers[_projectId][i] != msg.sender) {
                updatedSuppliers[j] = projectSuppliers[_projectId][i];
                j++;
            }
        }

        projectSuppliers[_projectId] = updatedSuppliers;

        _transferAmount(NATIVE, msg.sender, amount);
    }

    /**
     * @notice Extracts and returns the power of all suppliers for a given project.
     * @dev Iterates through the list of suppliers for the project and compiles their power into an array.
     * @param _projectId The ID of the project for which to extract supplier powers.
     * @return SupplierPower[] An array of SupplierPower structs, each representing a supplier's power for the project.
    */
    function _extractSupliers(bytes32 _projectId) internal view returns (SupplierPower[] memory) {

        SupplierPower[] memory suppliersPower = new SupplierPower[](projectSuppliers[_projectId].length);

        for (uint i = 0; i < projectSuppliers[_projectId].length; i++) {
            
            address supplierId = projectSuppliers[_projectId][i];
            uint256 supplierPower = projectSuppliersById[_projectId].supplyById[supplierId];

            suppliersPower[i] = SupplierPower(supplierId, uint256(supplierPower));
        }

        return suppliersPower;
    }

    /**
     * @notice Checks if a project with the given profile ID exists.
     * @dev A project exists if its profile has an owner address that is not the zero address.
     * @param _profileId The profile ID of the project to check.
     * @return bool Returns 'true' if the project exists, 'false' otherwise.
    */
    function _projectExists(bytes32 _profileId) private view returns (bool) {
        IRegistry.Profile memory profile = registry.getProfileById(_profileId);
        return profile.owner != address(0);
    }

    /**
     * @notice Creates and mints a new hat in the Hats contract.
     * @dev Mints the newly created hat to the specified wearers. Updates the project's hat information based on the type of hat.
     * @param _hatName The name of the hat to create.
     * @param _hatWearers An array of addresses to whom the hat will be minted.
     * @param _imageURI The URI of the hat's image.
     * @param _projectId The ID of the project associated with the hat.
     * @param _isSupplier A boolean indicating if the hat is for suppliers (true) or executors (false).
    */
    function _createAndMintHat(
        string memory _hatName, 
        address[] memory _hatWearers, 
        string memory _imageURI, 
        bytes32 _projectId, 
        bool _isSupplier
    ) 
        private 
    {
        uint256 hat = hatsContract.createHat(
            managerHatID, 
            _hatName, 
            uint32(_hatWearers.length), 
            address(this), 
            address(this), 
            true, 
            _imageURI
        );

        for (uint i = 0; i < _hatWearers.length; i++){
            hatsContract.mintHat(hat, _hatWearers[i]);
        }

        if (_isSupplier){
            projectHats[_projectId].supplierHat = hat;
        }
        else {
            projectHats[_projectId].executorHat = hat;
        }
    }

    /// @notice Transfer an amount of a token to an address
    /// @param _token The token to transfer
    /// @param _to The address to transfer to
    /// @param _amount The amount to transfer
    function _transferAmount(address _token, address _to, uint256 _amount) internal {
        if (_token == NATIVE) {
            SafeTransferLib.safeTransferETH(_to, _amount);
        } else {
            SafeTransferLib.safeTransfer(_token, _to, _amount);
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    /// @notice This contract should be able to receive native token
    receive() external payable {}
}
