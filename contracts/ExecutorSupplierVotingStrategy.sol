// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import "hardhat/console.sol";
// External Libraries
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// Intefaces
import {IAllo} from "./interfaces/IAllo.sol";
import {IRegistry} from "./interfaces/IRegistry.sol";
// Core Contracts
import {BaseStrategy} from "./BaseStrategy.sol";
// Internal Libraries
import {Metadata} from "./libraries/Metadata.sol";
import {IHats} from "./interfaces/Hats/IHats.sol";



// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Direct Grants Simple Strategy.
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>
/// @notice Strategy used to allocate & distribute funds to recipients with milestone payouts. The milestones
///         are set by the recipient and the pool manager can accept or reject the milestone. The pool manager
///         can also reject the recipient.
contract ExecutorSupplierVotingStrategy is BaseStrategy, ReentrancyGuard {
    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Struct to hold details of an recipient
    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        uint256 grantAmount;
        Metadata metadata;
        Status recipientStatus;
        Status milestonesReviewStatus;
    }

    /// @notice Struct to hold milestone details
    struct Milestone {
        uint256 amountPercentage;
        Metadata metadata;
        Status milestoneStatus;
        string description;
    }

    // @notice Struct to hold the init params for the strategy
    struct InitializeData {
        uint256 supplierHat;
        uint256 executorHat;
        SupplierPower[] validSupliers;
        address hatsContractAddress;
    }

    struct OfferedMilestones {
        Milestone[] milestones;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => uint256) suppliersVotes;
    }

    struct SubmiteddMilestone {
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => uint256) suppliersVotes;
    }

    struct RejectProject {
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => uint256) suppliersVotes;
    }

    struct SupplierPower {
        address supplierId;
        uint256 supplierPowerr;
    }

    /// ===============================
    /// ========== Errors =============
    /// ===============================

    /// @notice Throws when the milestone is invalid.
    error INVALID_MILESTONE();

    error INVALID_MILESTONES_PERCENTAGE();

    /// @notice Throws when the milestone is already accepted.
    error MILESTONE_ALREADY_ACCEPTED();

    /// @notice Throws when the milestones are already set.
    error MILESTONES_ALREADY_SET();

    /// @notice Throws when the milestones are reviewed by supplier.
    error ALREADY_REVIEWED();

    /// @notice Throws when the allocation exceeds the pool amount.
    error ALLOCATION_EXCEEDS_POOL_AMOUNT();

    error INVALID_STATUS();

    error EXECUTOR_HAT_WEARING_REQUIRED();

    error SUPPLIER_HAT_WEARING_REQUIRED();

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted for the registration of a recipient and the status is updated.
    event RecipientStatusChanged(address recipientId, Status status);

    /// @notice Emitted for the submission of a milestone.
    event MilestoneSubmitted(address recipientId, uint256 milestoneId, Metadata metadata);
    event SubmittedvMilestoneReviewed(address recipientId, uint256 milestoneId, Status status);

    /// @notice Emitted for the status change of a milestone.
    event MilestoneStatusChanged(address recipientId, uint256 milestoneId, Status status);

    event ProjectRejectDeclined();
    event ProjectRejected();

    /// @notice Emitted for the milestones set.
    event MilestonesSet(address recipientId, uint256 milestonesLength);
    event MilestonesReviewed(address recipientId, Status status);
    event MilestonesOffered(address recipientId, uint256 milestonesLength);
    event OfferedMilestonesAccepted(address recipientId);
    event OfferedMilestonesRejected(address recipientId);

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Holds Supplier's Hat ID.
    uint256 public supplierHat;

    /// @notice Holds Executor's Hat ID.
    uint256 public executorHat;

    uint256 public totalSupply;
    uint256 public thresholdPercentage;

    /// @notice The 'Registry' contract interface.
    IRegistry private _registry;

    /// @notice The total amount allocated to grant/recipient.
    uint256 public allocatedGrantAmount;

    IHats public hatsContract;

    /// @notice Internal collection of accepted recipients able to submit milestones
    address[] private _acceptedRecipientIds;
    address[] private _suppliersStore;

    /// @notice This maps accepted recipients to their details
    /// @dev 'recipientId' to 'Recipient'
    mapping(address => Recipient) private _recipients;
    mapping(address => uint256) private _suplierPower;
    mapping(address => OfferedMilestones) offeredMilestones;

    RejectProject projectReject;

    /// @notice This maps accepted recipients to their milestones
    /// @dev 'recipientId' to 'Milestone'
    mapping(address => Milestone[]) public milestones;

    /// @notice This maps accepted recipients to their upcoming milestone
    /// @dev 'recipientId' to 'nextMilestone'
    mapping(address => uint256) public upcomingMilestone;
    mapping(uint256 => SubmiteddMilestone) public submittedvMilestones;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the Direct Grants Simple Strategy
    /// @param _allo The 'Allo' contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initialize the strategy
    /// @param _poolId ID of the pool
    /// @param _data The data to be decoded
    /// @custom:data (uint256 supplierHat, uint256 executorHat)
    function initialize(uint256 _poolId, bytes memory _data) external virtual override {
        (InitializeData memory initData) = abi.decode(_data, (InitializeData));
        _ExecutorSupplierVotingStrategy_init(_poolId, initData);
        emit Initialized(_poolId, _data);
    }

    /// @notice This initializes the BaseStrategy
    /// @dev You only need to pass the 'poolId' to initialize the BaseStrategy and the rest is specific to the strategy
    /// @param _poolId ID of the pool - required to initialize the BaseStrategy
    /// @param _initData The init params for the strategy (uint256 supplierHat, uint256 executorHat)
    function _ExecutorSupplierVotingStrategy_init(uint256 _poolId, InitializeData memory _initData) internal {
        // Initialize the BaseStrategy
        __BaseStrategy_init(_poolId);

        // Set the strategy specific variables
        supplierHat = _initData.supplierHat;
        executorHat = _initData.executorHat;
        thresholdPercentage = 70;
        hatsContract = IHats(_initData.hatsContractAddress);

        SupplierPower[] memory supliersPower =  _initData.validSupliers;

        for (uint i = 0; i < supliersPower.length; i++) {
            _suppliersStore.push(supliersPower[i].supplierId);
            _suplierPower[supliersPower[i].supplierId] = supliersPower[i].supplierPowerr;
            totalSupply += supliersPower[i].supplierPowerr;
        }

        _registry = allo.getRegistry();

        // Set the pool to active - this is required for the strategy to work and distribute funds
        // NOTE: There may be some cases where you may want to not set this here, but will be strategy specific
        _setPoolActive(true);
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get the recipient
    /// @param _recipientId ID of the recipient
    /// @return Recipient Returns the recipient
    function getRecipient(address _recipientId) external view returns (Recipient memory) {
        return _getRecipient(_recipientId);
    }

    /// @notice Get the status of the milestone of an recipient.
    /// @dev This is used to check the status of the milestone of an recipient and is strategy specific
    /// @param _recipientId ID of the recipient
    /// @param _milestoneId ID of the milestone
    /// @return Status Returns the status of the milestone using the 'Status' enum
    function getMilestoneStatus(address _recipientId, uint256 _milestoneId) external view returns (Status) {
        return milestones[_recipientId][_milestoneId].milestoneStatus;
    }

    /// @notice Get the milestones.
    /// @param _recipientId ID of the recipient
    /// @return Milestone[] Returns the milestones for a 'recipientId'
    function getMilestones(address _recipientId) external view returns (Milestone[] memory) {
        return milestones[_recipientId];
    }

    function getOfferedMilestonesVotesFor(address _recipientId) external view returns (uint256) {
        return offeredMilestones[_recipientId].votesFor;
    }

    function getOfferedMilestonesVotesAgainst(address _recipientId) external view returns (uint256) {
        return offeredMilestones[_recipientId].votesAgainst;
    }

    function getSupplierOfferedMilestonesVote(address _recipientId, address _supplier) external view returns (uint256) {
        return offeredMilestones[_recipientId].suppliersVotes[_supplier];
    }

    function getSubmittedMilestonesVotesFor(uint256 _milestoneId) external view returns (uint256) {
        return submittedvMilestones[_milestoneId].votesFor;
    }

    function getSubmittedMilestonesVotesAgainst(uint256 _milestoneId) external view returns (uint256) {
        return submittedvMilestones[_milestoneId].votesAgainst;
    }

    function getSupplierSubmittedMilestonesVote(uint256 _milestoneId, address _supplier) external view returns (uint256) {
        return submittedvMilestones[_milestoneId].suppliersVotes[_supplier];
    }

    function getUpcomingMilestone(address _recipientId) external view returns (uint256) {
        return upcomingMilestone[_recipientId];
    }

    function getRejectProjectVotesFor() external view returns (uint256) {
        return projectReject.votesFor;
    }

    function getRejectProjectVotesAgainst() external view returns (uint256) {
        return projectReject.votesAgainst;
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    function setThresholdPercentage(uint256 _newPercentage, bytes32 _profileId) external {
        require(_registry.isOwnerOfProfile(_profileId, msg.sender), "UNAUTHORIZED");
        require(_newPercentage > 0, "Percentage must be greater than zero");
        require(_newPercentage <= 100, "Invalid percentage");
        thresholdPercentage = _newPercentage;
    }

    function offerMilestones(address _recipientId, Milestone[] memory _milestones) external {

        if (!hatsContract.isWearerOfHat( msg.sender, executorHat)){
            revert EXECUTOR_HAT_WEARING_REQUIRED();
        }

        bool isRecipientCreator = (msg.sender == _recipientId) || _isProfileMember(_recipientId, msg.sender);
        if (!isRecipientCreator) {
            revert UNAUTHORIZED();
        }

        Recipient storage recipient = _recipients[_recipientId];

        // Check if the recipient is accepted, otherwise revert
        if (recipient.recipientStatus != Status.Accepted) {
            revert RECIPIENT_NOT_ACCEPTED();
        }

        // Check if the milestones have already been reviewed and set, and if so, revert
        if (recipient.milestonesReviewStatus == Status.Accepted) {
            revert MILESTONES_ALREADY_SET();
        }

        _resetOfferedMilestones(_recipientId);

        for (uint i = 0; i < _milestones.length; i++) {
            offeredMilestones[_recipientId].milestones.push(_milestones[i]);
        }

        emit MilestonesOffered( _recipientId, _milestones.length);
    }

    function getOffeeredMilestones(address _recipientId) external view returns (Milestone[] memory) {
        return offeredMilestones[_recipientId].milestones;
    }

    /// @notice Set milestones of the recipient
    /// @dev Emits a 'MilestonesReviewed()' event
    /// @param _recipientId ID of the recipient
    /// @param _status The status of the milestone review

    function reviewOfferedtMilestones(address _recipientId, Status _status) external onlyPoolManager(msg.sender) {
        
        if (!hatsContract.isWearerOfHat( msg.sender, supplierHat)){
            revert SUPPLIER_HAT_WEARING_REQUIRED();
        }

        if (offeredMilestones[_recipientId].suppliersVotes[msg.sender] > 0){
            revert ALREADY_REVIEWED();
        }

        Recipient storage recipient = _recipients[_recipientId];

        if (recipient.milestonesReviewStatus == Status.Accepted) {
            revert MILESTONES_ALREADY_SET();
        }

        uint256 managerVotingPower = _suplierPower[msg.sender];
        uint256 threshold = totalSupply * thresholdPercentage / 100;

        offeredMilestones[_recipientId].suppliersVotes[msg.sender] = managerVotingPower;

        if (_status == Status.Accepted) {

            offeredMilestones[_recipientId].votesFor += managerVotingPower;

            if (offeredMilestones[_recipientId].votesFor > threshold) {

                _recipients[_recipientId].milestonesReviewStatus = _status;
                _setMilestones(_recipientId, offeredMilestones[_recipientId].milestones);
                emit OfferedMilestonesAccepted(_recipientId);
            }
        }
        else if (_status == Status.Rejected){

            offeredMilestones[_recipientId].votesAgainst += managerVotingPower;

            if (offeredMilestones[_recipientId].votesAgainst > threshold) {
                _recipients[_recipientId].milestonesReviewStatus = _status;
                _resetOfferedMilestones(_recipientId);
                emit OfferedMilestonesRejected(_recipientId);
            }
        }

        emit MilestonesReviewed(_recipientId, _status);
    }

    /// @notice Submit milestone by the recipient.
    /// @dev 'msg.sender' must be the 'recipientId' (this depends on whether your using registry gating) and must be a member
    ///      of a 'Profile' to submit a milestone and '_recipientId'.
    ///      must NOT be the same as 'msg.sender'. Emits a 'MilestonesSubmitted()' event.
    /// @param _recipientId ID of the recipient
    /// @param _metadata The proof of work
    function submitMilestone(address _recipientId, uint256 _milestoneId, Metadata calldata _metadata) external {
        
        if (!hatsContract.isWearerOfHat( msg.sender, executorHat)){
            revert EXECUTOR_HAT_WEARING_REQUIRED();
        }
        
        // Check if the '_recipientId' is the same as 'msg.sender' and if it is NOT, revert. This
        if (_recipientId != msg.sender) {
            revert UNAUTHORIZED();
        }

        Recipient memory recipient = _recipients[_recipientId];

        // Check if the recipient is 'Accepted', otherwise revert
        if (recipient.recipientStatus != Status.Accepted) {
            revert RECIPIENT_NOT_ACCEPTED();
        }

        Milestone[] storage recipientMilestones = milestones[_recipientId];

        // Check if the milestone is the upcoming one
        if (_milestoneId > recipientMilestones.length) {
            revert INVALID_MILESTONE();
        }

        Milestone storage milestone = recipientMilestones[_milestoneId];

        // Check if the milestone is accepted, otherwise revert
        if (milestone.milestoneStatus == Status.Accepted) {
            revert MILESTONE_ALREADY_ACCEPTED();
        }

        // Set the milestone metadata and status
        milestone.metadata = _metadata;
        milestone.milestoneStatus = Status.Pending;

        // Emit event for the milestone submission
        emit MilestoneSubmitted(_recipientId, _milestoneId, _metadata);
    }

    function reviewSubmitedMilestone(address _recipientId, uint256 _milestoneId, Status _status) external onlyPoolManager(msg.sender){

        if (!hatsContract.isWearerOfHat( msg.sender, supplierHat)){
            revert SUPPLIER_HAT_WEARING_REQUIRED();
        }

        if (submittedvMilestones[_milestoneId].suppliersVotes[msg.sender] > 0){
            revert ALREADY_REVIEWED();
        }

        Recipient memory recipient = _recipients[_recipientId];

        if (recipient.recipientStatus != Status.Accepted) {
            revert RECIPIENT_NOT_ACCEPTED();
        }

        Milestone[] storage recipientMilestones = milestones[_recipientId];

        if (_milestoneId > recipientMilestones.length) {
            revert INVALID_MILESTONE();
        }

        Milestone storage milestone = recipientMilestones[_milestoneId];

        if (milestone.milestoneStatus != Status.Pending) {
            revert INVALID_MILESTONE_STATUS();
        }

        uint256 managerVotingPower = _suplierPower[msg.sender];
        uint256 threshold = totalSupply * thresholdPercentage / 100;

        submittedvMilestones[_milestoneId].suppliersVotes[msg.sender] = managerVotingPower;

        if (_status == Status.Accepted) {

            submittedvMilestones[_milestoneId].votesFor += managerVotingPower;
            
            if (submittedvMilestones[_milestoneId].votesFor > threshold) { 
                milestone.milestoneStatus = _status;

                address[] memory recipientIds = new address[](1);
                recipientIds[0] = _recipientId;

                allo.distribute(poolId, recipientIds, "");

                emit MilestoneStatusChanged(_recipientId, _milestoneId, _status);
            }
        }
        else if (_status == Status.Rejected){

            submittedvMilestones[_milestoneId].votesAgainst += managerVotingPower;
            
            if (submittedvMilestones[_milestoneId].votesAgainst > threshold) { 
                milestone.milestoneStatus = _status;

                for (uint i = 0; i < _suppliersStore.length; i++){
                    submittedvMilestones[_milestoneId].suppliersVotes[_suppliersStore[i]] = 0;
                }

                delete submittedvMilestones[_milestoneId];
                emit MilestoneStatusChanged(_recipientId, _milestoneId, _status);
            }
        }
            
        emit SubmittedvMilestoneReviewed(_recipientId, _milestoneId, _status);
    }

    function rejetProject(Status _status) external onlyPoolManager(msg.sender){ 

        if (!hatsContract.isWearerOfHat( msg.sender, supplierHat)){
            revert SUPPLIER_HAT_WEARING_REQUIRED();
        }

        if (_status != Status.Accepted && _status != Status.Rejected) {
            revert INVALID_STATUS();
        }

        if (projectReject.suppliersVotes[msg.sender] > 0){
            revert ALREADY_REVIEWED();
        }

        uint256 managerVotingPower = _suplierPower[msg.sender];
        uint256 threshold = totalSupply * thresholdPercentage / 100;

        if (_status == Status.Accepted) {

            projectReject.votesFor += managerVotingPower;
            
            if (projectReject.votesFor > threshold) { 
                _setPoolActive(false);
                _distributeFundsBackToSuppliers();

                emit ProjectRejected();
            }
        }
        else if (_status == Status.Rejected){

            projectReject.votesAgainst += managerVotingPower;
            
            if (projectReject.votesAgainst > threshold) { 

                for (uint i = 0; i < _suppliersStore.length; i++){
                    projectReject.suppliersVotes[_suppliersStore[i]] = 0;
                }

                delete projectReject;

                emit ProjectRejectDeclined();
            }
        }
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Get recipient status
    /// @dev The global 'Status' is used at the protocol level and most strategies will use this.
    ///      todo: finish this
    /// @param _recipientId ID of the recipient
    /// @return Status Returns the global recipient status
    function _getRecipientStatus(address _recipientId) internal view override returns (Status) {
        return _getRecipient(_recipientId).recipientStatus;
    }

    function _distributeFundsBackToSuppliers() private { 

        for (uint i = 0; i < _suppliersStore.length; i++){

            uint256 percentage = _suplierPower[_suppliersStore[i]];
            uint256 amount = poolAmount * percentage / 1e18;
            IAllo.Pool memory pool = allo.getPool(poolId);

            _transferAmount(pool.token, _suppliersStore[i], amount);
        }
    }

    /// @notice Checks if address is eligible allocator.
    /// @dev This is used to check if the allocator is a pool manager and able to allocate funds from the pool
    /// @param _allocator Address of the allocator
    /// @return 'true' if the allocator is a pool manager, otherwise false
    function _isValidAllocator(address _allocator) internal view override returns (bool) {
        return allo.isPoolManager(poolId, _allocator);
    }

    function _resetOfferedMilestones(address _recipientId) internal {

        for (uint i = 0; i < _suppliersStore.length; i++){
            offeredMilestones[_recipientId].suppliersVotes[_suppliersStore[i]] = 0;
        }

        delete offeredMilestones[_recipientId];
    } 

    /// @notice Register a recipient to the pool.
    /// @dev Emits a 'Registered()' event
    /// @param _data The data to be decoded
    /// @custom:data (address recipientAddress, address registryAnchor, uint256 grantAmount, Metadata metadata)
    /// @param _sender The sender of the transaction
    /// @return recipientId The id of the recipient
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyActivePool
        returns (address recipientId)
    {
        address recipientAddress;
        address registryAnchor;
        bool isUsingRegistryAnchor;
        uint256 grantAmount;
        Metadata memory metadata;

        /// @custom:data (address recipientAddress, address registryAnchor, uint256 grantAmount, Metadata metadata)

        (recipientAddress, registryAnchor, grantAmount, metadata) =
            abi.decode(_data, (address, address, uint256, Metadata));

        // Check if the registry anchor is valid so we know whether to use it or not
        isUsingRegistryAnchor = registryAnchor != address(0);

        // Ternerary to set the recipient id based on whether or not we are using the 'registryAnchor' or 'recipientAddress'
        recipientId = isUsingRegistryAnchor ? registryAnchor : recipientAddress;
        if (isUsingRegistryAnchor && !_isProfileMember(recipientId, _sender)) {
            revert UNAUTHORIZED();
        }

        // Check if the recipient is not already accepted, otherwise revert
        if (_recipients[recipientId].recipientStatus == Status.Accepted) {
            revert RECIPIENT_ALREADY_ACCEPTED();
        }

        // Create the recipient instance
        Recipient memory recipient = Recipient({
            recipientAddress: recipientAddress,
            useRegistryAnchor: isUsingRegistryAnchor,
            grantAmount: grantAmount,
            metadata: metadata,
            recipientStatus: Status.Accepted,
            milestonesReviewStatus: Status.Pending
        });

        // Add the recipient to the accepted recipient ids mapping
        _recipients[recipientId] = recipient;

        // Emit event for the registration
        emit Registered(recipientId, _data, _sender);
    }

    /// @notice Allocate amount to recipent for direct grants.
    /// @dev '_sender' must be a pool manager to allocate. Emits 'RecipientStatusChanged() and 'Allocated()' events.
    /// @param _data The data to be decoded
    /// @custom:data (address recipientId, Status recipientStatus, uint256 grantAmount)
    /// @param _sender The sender of the allocation
    function _allocate(bytes memory _data, address _sender)
        internal
        virtual
        override
        nonReentrant
        // onlyPoolManager(_sender)
    {
        require(_sender == address(this), "UNAUTHORIZED allocate");
        
        // Decode the '_data'
        (address recipientId, Status recipientStatus, uint256 grantAmount) =
            abi.decode(_data, (address, Status, uint256));

        Recipient storage recipient = _recipients[recipientId];

        if (upcomingMilestone[recipientId] != 0) {
            revert MILESTONES_ALREADY_SET();
        }

        if (recipient.recipientStatus != Status.Accepted && recipientStatus == Status.Accepted) {
            IAllo.Pool memory pool = allo.getPool(poolId);
            allocatedGrantAmount += grantAmount;

            // Check if the allocated grant amount exceeds the pool amount and reverts if it does
            if (allocatedGrantAmount > poolAmount) {
                revert ALLOCATION_EXCEEDS_POOL_AMOUNT();
            }

            recipient.grantAmount = grantAmount;
            recipient.recipientStatus = Status.Accepted;

            // Emit event for the acceptance
            emit RecipientStatusChanged(recipientId, Status.Accepted);

            // Emit event for the allocation
            emit Allocated(recipientId, recipient.grantAmount, pool.token, _sender);
        } else if (
            recipient.recipientStatus != Status.Rejected // no need to reject twice
                && recipientStatus == Status.Rejected
        ) {
            recipient.recipientStatus = Status.Rejected;

            // Emit event for the rejection
            emit RecipientStatusChanged(recipientId, Status.Rejected);
        }
    }

    /// @notice Distribute the upcoming milestone to recipients.
    /// @dev '_sender' must be a pool manager to distribute.
    /// @param _recipientIds The recipient ids of the distribution
    /// @param _sender The sender of the distribution
    function _distribute(address[] memory _recipientIds, bytes memory, address _sender)
        internal
        virtual
        override
    {
        require(_sender == address(this), "UNAUTHORIZED distribute");

        uint256 recipientLength = _recipientIds.length;
        for (uint256 i; i < recipientLength;) {
            _distributeUpcomingMilestone(_recipientIds[i], _sender);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Distribute the upcoming milestone.
    /// @dev Emits 'MilestoneStatusChanged() and 'Distributed()' events.
    /// @param _recipientId The recipient of the distribution
    /// @param _sender The sender of the distribution
    function _distributeUpcomingMilestone(address _recipientId, address _sender) private {
        uint256 milestoneToBeDistributed = upcomingMilestone[_recipientId];
        Milestone[] storage recipientMilestones = milestones[_recipientId];

        Recipient memory recipient = _recipients[_recipientId];
        Milestone storage milestone = recipientMilestones[milestoneToBeDistributed];

        // check if milestone is not rejected or already paid out
        if (milestoneToBeDistributed > recipientMilestones.length) {
            revert INVALID_MILESTONE();
        }

        if (milestone.milestoneStatus != Status.Accepted) {
            revert INVALID_MILESTONE_STATUS();
        }

        // Calculate the amount to be distributed for the milestone
        uint256 amount = recipient.grantAmount * milestone.amountPercentage / 1e18;

        // Get the pool, subtract the amount and transfer to the recipient
        IAllo.Pool memory pool = allo.getPool(poolId);

        poolAmount -= amount;
        _transferAmount(pool.token, recipient.recipientAddress, amount);

        // Increment the upcoming milestone
        upcomingMilestone[_recipientId]++;

        // Emit events for the distribution
        emit Distributed(_recipientId, recipient.recipientAddress, amount, _sender);
    }

    /// @notice Check if sender is a profile owner or member.
    /// @param _anchor Anchor of the profile
    /// @param _sender The sender of the transaction
    /// @return 'true' if the sender is the owner or member of the profile, otherwise 'false'
    function _isProfileMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry.Profile memory profile = _registry.getProfileByAnchor(_anchor);
        return _registry.isOwnerOrMemberOfProfile(profile.id, _sender);
    }

    /// @notice Get the recipient.
    /// @param _recipientId ID of the recipient
    /// @return recipient Returns the recipient information
    function _getRecipient(address _recipientId) internal view returns (Recipient memory recipient) {
        recipient = _recipients[_recipientId];
    }

    /// @notice Get the payout summary for the accepted recipient.
    /// @return Returns the payout summary for the accepted recipient

    
    function _getPayout(address _recipientId, bytes memory) internal view override returns (PayoutSummary memory) {
        Recipient memory recipient = _getRecipient(_recipientId);
        return PayoutSummary(recipient.recipientAddress, recipient.grantAmount);
    }

    /// @notice Set the milestones for the recipient.
    /// @param _recipientId ID of the recipient
    /// @param _milestones The milestones to be set
    function _setMilestones(address _recipientId, Milestone[] memory _milestones) internal {
        uint256 totalAmountPercentage;

        // Clear out the milestones and reset the index to 0
        if (milestones[_recipientId].length > 0) {
            delete milestones[_recipientId];
        }

        uint256 milestonesLength = _milestones.length;

        // Loop through the milestones and set them
        for (uint256 i; i < milestonesLength;) {
            Milestone memory milestone = _milestones[i];

            // Reverts if the milestone status is 'None'
            if (milestone.milestoneStatus != Status.None) {
                revert INVALID_MILESTONE_STATUS();
            }

            // TODO: I see we check on line 649, but it seems we need to check when added it is NOT greater than 100%?
            // Add the milestone percentage amount to the total percentage amount
            totalAmountPercentage += milestone.amountPercentage;

            // Add the milestone to the recipient's milestones
            milestones[_recipientId].push(milestone);

            unchecked {
                i++;
            }
        }

        if (totalAmountPercentage != 1e18) {
            revert INVALID_MILESTONES_PERCENTAGE();
        }

        bytes memory encodedAllocateParams = abi.encode(
            _recipientId,
            Status.Accepted,
            totalSupply
        );

        allo.allocate(poolId, encodedAllocateParams);

        emit MilestonesSet(_recipientId, milestonesLength);
    }

    /// @notice This contract should be able to receive native token
    receive() external payable {}
}
