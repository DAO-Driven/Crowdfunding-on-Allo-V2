// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import {Metadata} from "./Metadata.sol";
import "../interfaces/IRegistry.sol";


struct InitializeData {
    bool registryGating;
    bool metadataRequired;
    bool grantAmountRequired;
    SupplierPower[] supliersPower;
}

struct NewRecipientParams {
    address recipientAddress;
    address registryAnchor;
    uint256 grantAmount;
    Metadata metadata;
}

struct ProjectSupply {
    uint256 need;
    uint256 has;    
}

struct Suppliers {
    address[] suppliers;
    mapping(address => int256) supplyById;   
}

struct SupplierPower {
    address supplierId;
    uint256 supplierPowerr;
}

struct ActiveProjects {
    bytes32 projectId;
    uint256 poolId;
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