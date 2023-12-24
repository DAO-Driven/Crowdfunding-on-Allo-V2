// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IRegistry.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Errors} from "./libraries/Errors.sol";
import {Transfer} from "./libraries/Transfer.sol";
import "./libraries/Native.sol";
import {IAllo} from "./interfaces/IAllo.sol";
import "hardhat/console.sol";


contract Manager is ReentrancyGuard, Errors, Transfer{

    enum Status {
        None,
        Pending,
        Accepted,
        Rejected,
        Appealed,
        InReview,
        Canceled
    }

    struct InitializeData {
        bool registryGating;
        bool metadataRequired;
        bool grantAmountRequired;
        SupplierPower[] supliersPower;
    }

    struct ProjectSupply {
        uint256 need;
        uint256 has;   
        string name;
        string description; 
    }

    struct Suppliers {
        address[] suppliers;
        mapping(address => int256) supplyById;   
    }

    struct SupplierPower {
        address supplierId;
        uint256 supplierPowerr;
    }

    IRegistry registry;
    IAllo allo;
    address strategy;

    /// ================================
    /// ========== Storage =============
    /// ================================

    bytes32[] profiles;
    mapping(bytes32 => ProjectSupply) pojectSupply;
    mapping(bytes32 => Suppliers) suppliers;
    mapping(bytes32 => address) projectExecutor;
    mapping(bytes32 => uint256) projectPool;

    /// ===============================
    /// ========== Events =============
    /// ===============================

    event ProjectFunded(bytes32 indexed projectId, uint256 amount);
    event ProjectPoolCreeated(bytes32 projectId, uint256 poolId);

    constructor(address alloAddress, address _strategy) {
        
        allo = IAllo(alloAddress);
        strategy = _strategy;

        address registryAddress = address(allo.getRegistry());
        registry = IRegistry(registryAddress);
    }

    function getProfile(bytes32 profileId) public view returns (IRegistry.Profile memory) {
        return registry.getProfileById(profileId);
    }

    function getProjectPool(bytes32 projectId) public view returns (uint256) {
        return projectPool[projectId];
    }

    function registerProject( 
        uint256 _needs,
        uint256 _nonce,
        string memory _name,
        Metadata memory _metadata,
        address _recipient,
        string memory _description
    ) external returns (bytes32 profileId) {

        address[] memory members = new address[](2);
        members[0] = _recipient;
        members[1] = address(this);

        profileId = registry.createProfile(_nonce, _name, _metadata, address(this), members);
        profiles.push(profileId);
        pojectSupply[profileId].need += _needs;
        pojectSupply[profileId].name = _name;
        pojectSupply[profileId].description = _description;

        projectExecutor[profileId] = _recipient;

        return profileId;
    }

    function getProfiles() public view returns (bytes32[] memory){
        return profiles;
    }

    function supplyProject(bytes32 _projectId, uint256 _amount) external payable nonReentrant {

        require(_projectExists(_projectId), "Project does not exist");
        if (_amount == 0 || _amount != msg.value) revert NOT_ENOUGH_FUNDS();
        if (suppliers[_projectId].supplyById[msg.sender] < 0) revert SUPPLY_IS_ALLOWED_ONLY_ONCE();

        pojectSupply[_projectId].has += _amount;
        suppliers[_projectId].supplyById[msg.sender] = int256(_amount);
        suppliers[_projectId].suppliers.push(msg.sender);

        emit ProjectFunded(_projectId, _amount);

        if (pojectSupply[_projectId].has >= pojectSupply[_projectId].need){

            SupplierPower[] memory validSupliers = _extractValidSupliers(_projectId);

            InitializeData memory initData = InitializeData({
                registryGating: false,
                metadataRequired: false,
                grantAmountRequired: false,
                supliersPower: validSupliers
            });

            address[] memory managers = new address[](validSupliers.length + 1);

            for (uint i = 0; i < validSupliers.length; i++) {
                managers[i] = (validSupliers[i].supplierId);
            }

            managers[validSupliers.length] = address(this);

            Metadata memory metadata = Metadata({
                protocol: 1,
                pointer: "empty pointer"
            });

            bytes memory encodedInitData = abi.encode(initData);
            uint256 grantAmount = pojectSupply[_projectId].need;


            uint256 pool = allo.createPoolWithCustomStrategy{value: msg.value}(
                _projectId,
                strategy,
                encodedInitData,
                NATIVE,
                0,
                metadata,
                managers
            );

            require(address(this).balance >= pojectSupply[_projectId].need, "Insufficient balance in contract");

            allo.fundPool{value: pojectSupply[_projectId].need}(pool, pojectSupply[_projectId].need);

            bytes memory encodedRecipientParams = abi.encode(
                projectExecutor[_projectId],
                0x0000000000000000000000000000000000000000,
                grantAmount,
                metadata
            );

            allo.registerRecipient(pool, encodedRecipientParams);

            projectPool[_projectId] = pool;

            emit ProjectPoolCreeated( _projectId, pool);
        }
    }

    function revokeProjectSupply(bytes32 _projectId) external nonReentrant {
        require(_projectExists(_projectId), "Project does not exist");

        int256 amount = suppliers[_projectId].supplyById[msg.sender];

        require(amount > 0, "SUPPLY NOT FOUND");

        uint256 refundAmount = uint256(amount);

        suppliers[_projectId].supplyById[msg.sender] = -1;
        pojectSupply[_projectId].has -= refundAmount;

        _transferAmount(NATIVE, msg.sender, refundAmount);
    }

    function getProjectSupply(bytes32 _projectId) public view returns (ProjectSupply memory) {
        return pojectSupply[_projectId];
    }

    function _extractValidSupliers(bytes32 _projectId) internal view returns (SupplierPower[] memory) {
        Suppliers storage projectSuppliers = suppliers[_projectId];
        SupplierPower[] memory suppliersPower = new SupplierPower[](projectSuppliers.suppliers.length);
        uint actualLength = 0;

        for (uint i = 0; i < projectSuppliers.suppliers.length; i++) {
            address supplierId = projectSuppliers.suppliers[i];
            int256 supplierPower = projectSuppliers.supplyById[supplierId];

            if (supplierPower > 0) {
                suppliersPower[actualLength] = SupplierPower(supplierId, uint256(supplierPower));
                actualLength++;
            }
        }

        SupplierPower[] memory validSuppliersPower = new SupplierPower[](actualLength);

        for (uint i = 0; i < actualLength; i++) {
            validSuppliersPower[i] = suppliersPower[i];
        }

        return validSuppliersPower;
    }

    function _projectExists(bytes32 profileId) public view returns (bool) {
        IRegistry.Profile memory profile = registry.getProfileById(profileId);
        return profile.owner != address(0);
    }
    
    /// @notice This contract should be able to receive native token
    receive() external payable {}
}
