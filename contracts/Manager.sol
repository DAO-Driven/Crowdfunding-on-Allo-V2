// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IRegistry.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Errors} from "./libraries/Errors.sol";
import {Transfer} from "./libraries/Transfer.sol";
import "./libraries/Native.sol";
import {IAllo} from "./interfaces/IAllo.sol";
import {IStrategyFactory} from "./interfaces/IStrategyFactory.sol";
import {IHats} from "./interfaces/Hats/IHats.sol";
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
        uint256 supplierHat;
        uint256 executorHat;
        SupplierPower[] supliersPower;
    }

    struct ProjectSupply {
        uint256 need;
        uint256 has;   
        string name;
        string description; 
    }

    struct SuppliersById {
        mapping(address => uint256) supplyById;   
    }

    struct SupplierPower {
        address supplierId;
        uint256 supplierPowerr;
    }

    struct Hats {
        uint256 executorHat;
        uint256 supplierHat;
    }

    IRegistry registry;
    IAllo allo;
    address strategy;
    IStrategyFactory strategyFactory;
    IHats public hatsContract;
    uint256 managerHatID;

    /// ================================
    /// ========== Storage =============
    /// ================================

    bytes32[] profiles;
    mapping(bytes32 => address[]) projectSuppliers;
    mapping(bytes32 => SuppliersById) projectSuppliersById;
    mapping(bytes32 => ProjectSupply) pojectSupply;
    mapping(bytes32 => address) projectExecutor;
    mapping(bytes32 => uint256) projectPool;
    mapping(bytes32 => address) projectStrategy;
    mapping(bytes32 => Hats) projectHats;

    /// ===============================
    /// ========== Events =============
    /// ===============================

    event ProjectFunded(bytes32 indexed projectId, uint256 amount);
    event ProjectPoolCreeated(bytes32 projectId, uint256 poolId);

    constructor(address alloAddress, address _strategy, address _strategyFactory, address _hatsContractAddress, uint256 _managerHatID) {
        allo = IAllo(alloAddress);
        strategy = _strategy;
        strategyFactory = IStrategyFactory(_strategyFactory);
        hatsContract = IHats(_hatsContractAddress);
        managerHatID = _managerHatID;
        address registryAddress = address(allo.getRegistry());
        registry = IRegistry(registryAddress);
    }

    function getProfile(bytes32 _projectId) public view returns (IRegistry.Profile memory) {
        return registry.getProfileById(_projectId);
    }

    function getProjectPool(bytes32 _projectId) public view returns (uint256) {
        return projectPool[_projectId];
    }

    function getProjectSuppliers(bytes32 _projectId) public view returns (address[] memory) {
        return projectSuppliers[_projectId];
    }

    function getProjectSupplierById(bytes32 _projectId, address _supplier) public view returns (uint256) {
        return projectSuppliersById[_projectId].supplyById[_supplier];
    }

    function getProjectExecutor(bytes32 _projectId) public view returns (address) {
        return projectExecutor[_projectId];
    }

    function getProjectStrategy(bytes32 _projectId) public view returns (address) {
        return projectStrategy[_projectId];
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

        pojectSupply[_projectId].has += _amount;

        if (projectSuppliersById[_projectId].supplyById[msg.sender] == 0){
            projectSuppliers[_projectId].push(msg.sender);
        }

        projectSuppliersById[_projectId].supplyById[msg.sender] += _amount;

        emit ProjectFunded(_projectId, _amount);

        if (pojectSupply[_projectId].has >= pojectSupply[_projectId].need){

            SupplierPower[] memory validSupliers = _extractSupliers(_projectId);
            address[] memory managers = new address[](validSupliers.length + 1);

            for (uint i = 0; i < validSupliers.length; i++) {
                managers[i] = (validSupliers[i].supplierId);
            }

            managers[validSupliers.length] = address(this);

            _createAndMintHat(
                "SUPPLIER_HAT", 
                managers, 
                "ipfs://bafkreiey2a5jtqvjl4ehk3jx7fh7edsjqmql6vqxdh47znsleetug44umy/",
                _projectId,
                true
            );

            address[] memory executorAddresses = new address[](1);
            executorAddresses[0] = projectExecutor[_projectId];

            _createAndMintHat(
                "EXECUTOR_HAT", 
                executorAddresses, 
                "ipfs://bafkreih7hjg4ehf4lqdoqstlkjxvjy7zfnza4keh2knohsle3ikjja3g2i/",
                _projectId,
                false
            );

            bytes memory encodedInitData = abi.encode(InitializeData({
                supplierHat: projectHats[_projectId].supplierHat,
                executorHat: projectHats[_projectId].executorHat,
                supliersPower: validSupliers
            }));

            projectStrategy[_projectId] = strategyFactory.createStrategy(strategy);

            uint256 pool = allo.createPoolWithCustomStrategy{value: msg.value}(
                _projectId,
                projectStrategy[_projectId],
                encodedInitData,
                NATIVE,
                0,
                Metadata({
                    protocol: 1,
                    pointer: "manager webpage link"
                }),
                managers
            );

            require(address(this).balance >= pojectSupply[_projectId].need, "Insufficient balance in contract");

            allo.fundPool{value: pojectSupply[_projectId].need}(pool, pojectSupply[_projectId].need);

            bytes memory encodedRecipientParams = abi.encode(
                projectExecutor[_projectId],
                0x0000000000000000000000000000000000000000,
                pojectSupply[_projectId].need,
                Metadata({
                    protocol: 1,
                    pointer: "manager webpage link"
                })
            );

            allo.registerRecipient(pool, encodedRecipientParams);
            projectPool[_projectId] = pool;

            emit ProjectPoolCreeated( _projectId, pool);
        }
    }

    function revokeProjectSupply(bytes32 _projectId) external nonReentrant {
        require(_projectExists(_projectId), "Project does not exist");

        uint256 amount = projectSuppliersById[_projectId].supplyById[msg.sender];
        require(amount > 0, "SUPPLY NOT FOUND");

        delete projectSuppliersById[_projectId].supplyById[msg.sender];

        pojectSupply[_projectId].has -= amount;

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

    function getProjectSupply(bytes32 _projectId) public view returns (ProjectSupply memory) {
        return pojectSupply[_projectId];
    }

    function _extractSupliers(bytes32 _projectId) internal view returns (SupplierPower[] memory) {

        SupplierPower[] memory suppliersPower = new SupplierPower[](projectSuppliers[_projectId].length);

        for (uint i = 0; i < projectSuppliers[_projectId].length; i++) {
            
            address supplierId = projectSuppliers[_projectId][i];
            uint256 supplierPower = projectSuppliersById[_projectId].supplyById[supplierId];

            suppliersPower[i] = SupplierPower(supplierId, uint256(supplierPower));
        }

        return suppliersPower;
    }

    function _projectExists(bytes32 _profileId) private view returns (bool) {
        IRegistry.Profile memory profile = registry.getProfileById(_profileId);
        return profile.owner != address(0);
    }

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
    
    /// @notice This contract should be able to receive native token
    receive() external payable {}
}
