// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IRegistry.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Errors} from "./libraries/Errors.sol";
import {Transfer} from "./libraries/Transfer.sol";
import "./libraries/Native.sol";
import { DirectGrantsSimpleStrategy } from "./DirectGrantsSimpleStrategy.sol";
import {IAlloV2, InitializeData, NewRecipientParams, Status, ProjectSupply, Suppliers, SupplierPower} from "./libraries/Helpers.sol";


import "hardhat/console.sol";

contract Manager is ReentrancyGuard, Errors, Transfer{
    IRegistry registry;
    IAlloV2 allo;
    address strategy;

    /// ================================
    /// ========== Storage =============
    /// ================================

    bytes32[] private profiles;
    mapping(bytes32 => ProjectSupply) private pojectSupply;
    mapping(bytes32 => Suppliers) private suppliers;

    /// ===============================
    /// ========== Events =============
    /// ===============================

    event ProjectFunded(bytes32 indexed projectId, uint256 amount);
    event ProjectPoolCreeated(bytes32 projectId, uint256 poolId);

    constructor(address alloAddress, address _strategy) {
        
        allo = IAlloV2(alloAddress);
        strategy = _strategy;

        address registryAddress = address(allo.getRegistry());
        registry = IRegistry(registryAddress);
    }

    function getProfile(bytes32 profileId) public view returns (IRegistry.Profile memory) {
        return registry.getProfileById(profileId);
    }

    function registerProject( 
        uint256 _needs,
        uint256 _nonce,
        string memory _name,
        Metadata memory _metadata,
        address _owner,
        address[] memory _members
    ) external returns (bytes32 profileId) {
        profileId = registry.createProfile(_nonce, _name, _metadata, _owner, _members);
        profiles.push(profileId);
        pojectSupply[profileId].need += _needs;

        return profileId;
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

            address[] memory managers = new address[](validSupliers.length);

            for (uint i = 0; i < validSupliers.length; i++) {
                managers[i] = (validSupliers[i].supplierId);
            }

            Metadata memory metadata = Metadata({
                protocol: 1,
                pointer: "empty pointer"
            });

            bytes memory encodedInitData = abi.encode(initData);

            uint256 pool = allo.createPoolWithCustomStrategy{value: msg.value}(
                _projectId,
                strategy,
                encodedInitData,
                NATIVE,
                0,
                metadata,
                managers
            );

            console.log("======> NEW POOL:", pool);

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

    // Helper function to check if a project exists
    function _projectExists(bytes32 profileId) public view returns (bool) {
        IRegistry.Profile memory profile = registry.getProfileById(profileId);
        return profile.owner != address(0);
    }

    function getProfiles() external view returns (bytes32[] memory) {
        return profiles;
    }

    function getAlloRegistry() external view returns (IRegistry) {
        return allo.getRegistry();
    }

    function createPoolForDirectGrants(
        bytes32 _profileId,
        address _strategy,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) public payable returns (uint256) {
        
        // InitializeData memory initData = InitializeData({
        //     registryGating: false,
        //     metadataRequired: false,
        //     grantAmountRequired: false
        // });


        // bytes memory encodedInitData = abi.encode(initData);

        // return allo.createPoolWithCustomStrategy{value: msg.value}(
        //     _profileId,
        //     _strategy,
        //     encodedInitData,
        //     _token,
        //     _amount,
        //     _metadata,
        //     _managers
        // );
    }

    function supplyPool(uint256 _poolId, uint256 _amount) external payable {
        require(address(this).balance >= _amount, "Insufficient balance in contract");
        return allo.fundPool{value: _amount}(_poolId, _amount);
    }

    function registerRecipient(
        uint256 _poolId,
        address _recipientAddress,
        address _registryAnchor,
        uint256 _grantAmount,
        Metadata memory _metadata
    )
        external
        returns (address recipientId)
    {
        
        bytes memory encodedRecipientParams = abi.encode(
            _recipientAddress,
            _registryAnchor,
            _grantAmount,
            _metadata
        );

        return allo.registerRecipient(_poolId, encodedRecipientParams);
    }

    function allocateFundsToRecipient(
        uint256 _poolId,
        address _recipientId, 
        Status _recipientStatus, 
        uint256 _grantAmount
    )
        external
    {

        bytes memory encodedAllocateParams = abi.encode(
            _recipientId,
            _recipientStatus,
            _grantAmount
        );

        return allo.allocate(_poolId, encodedAllocateParams);
    }

    function distributeFundsToRecipient(uint256 _poolId, address[] memory _recipientIds)
        external
    {
        bytes memory emptyData = "";

        return allo.distribute(_poolId, _recipientIds, emptyData);
    }
    
    /// @notice This contract should be able to receive native token
    receive() external payable {}
}
