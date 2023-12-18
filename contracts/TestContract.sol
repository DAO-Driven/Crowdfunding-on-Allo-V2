// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IRegistry.sol";
import { DirectGrantsSimpleStrategy } from "./DirectGrantsSimpleStrategy.sol";


interface IAlloV2 {
    function createPoolWithCustomStrategy(
        bytes32 _profileId,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external payable returns (uint256 poolId);

    function getRegistry() external view returns (IRegistry);
    function fundPool(uint256 _poolId, uint256 _amount) external payable;
    function registerRecipient(uint256 _poolId, bytes memory _data) external payable returns (address);
    function allocate(uint256 _poolId, bytes memory _data) external payable;
    function distribute(uint256 _poolId, address[] memory _recipientIds, bytes memory _data) external;
}


contract TestContract {
    IRegistry registry;
    IAlloV2 allo;

    struct InitializeParams {
        bool useRegistryAnchor;
        uint64 allocationStartTime;
        uint64 allocationEndTime;
        uint256 approvalThreshold;
        uint256 maxRequestedAmount;
    }

    struct InitializeData {
        bool registryGating;
        bool metadataRequired;
        bool grantAmountRequired;
    }

    struct NewRecipientParams {
        address recipientAddress;
        address registryAnchor;
        uint256 grantAmount;
        Metadata metadata;
    }

    enum Status {
        None,
        Pending,
        Accepted,
        Rejected,
        Appealed,
        InReview,
        Canceled
    }

    constructor() {
        address registryAddress = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
        registry = IRegistry(registryAddress);

        address alloAddress = 0x1133eA7Af70876e64665ecD07C0A0476d09465a1;
        allo = IAlloV2(alloAddress);
    }

    function getProfile(bytes32 profileId) public view returns (IRegistry.Profile memory) {
        return registry.getProfileById(profileId);
    }

    function createProfile( 
        uint256 _nonce,
        string memory _name,
        Metadata memory _metadata,
        address _owner,
        address[] memory _members
    ) external returns (bytes32 profileId) {

        return registry.createProfile( _nonce, _name, _metadata, _owner, _members);
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
        
        // Create an instance of InitializeParams with the correct structure
        InitializeData memory initData = InitializeData({
            registryGating: false,
            metadataRequired: false,
            grantAmountRequired: false
        });

        bytes memory encodedInitData = abi.encode(initData);

        return allo.createPoolWithCustomStrategy{value: msg.value}(
            _profileId,
            _strategy,
            encodedInitData,
            _token,
            _amount,
            _metadata,
            _managers
        );
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
