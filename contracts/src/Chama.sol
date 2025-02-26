// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IChama} from "@contracts/IChama.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";

contract Chama is IChama {
    uint256 public groupId;

    mapping(uint256 => Group) public groups;

    mapping(address => uint256) public balances;

    constructor() {}

    modifier onlyCreator(uint256 _groupId) {
        if (groups[_groupId].creator != msg.sender) revert NotCreator();
        _;
    }

    function createGroup(
        CreateGroupParams memory _group
    ) external override returns (uint256) {
        if (_group.maxMembers == 0) revert MaxMembersZero();
        if (_group.cycleDays == 0) revert CycleDaysZero();
        if (_group.contributionAmount == 0) revert ContributionAmountZero();

        groupId++;

        Group storage group = groups[groupId];
        group.id = groupId;
        group.name = _group.name;
        group.description = _group.description;
        group.vault = _group.vault;
        group.maxMembers = _group.maxMembers;
        group.cycleDays = _group.cycleDays;
        group.contributionAmount = _group.contributionAmount;
        group.isActive = true;
        group.creator = msg.sender;
        group.memberId = 1;
        group.joinFee = _group.joinFee;
        group.lateFee = _group.lateFee;

        emit GroupCreated(groupId, _group.name, group.creator);

        return groupId;
    }

    function getGroup(uint256 _id) external view returns (GroupParams memory) {
        Group storage group = groups[_id];

        if (group.id == 0) revert GroupNotFound();

        return
            GroupParams({
                id: group.id,
                name: group.name,
                description: group.description,
                isActive: group.isActive,
                creator: group.creator,
                vault: group.vault,
                memberId: group.memberId,
                cycleDays: group.cycleDays,
                maxMembers: group.maxMembers,
                contributionAmount: group.contributionAmount,
                joinFee: group.joinFee,
                lateFee: group.lateFee,
                currentRound: group.currentRound
            });
    }

    function joinGroup(uint256 _id) external payable override {
        Group storage group = groups[_id];

        if (group.id == 0) revert GroupNotFound();
        if (group.memberId >= group.maxMembers) revert GroupFull();
        if (!group.isActive) revert GroupInactive();
        if (group.currentRound > 0) revert GroupStarted();
        if (group.memberIds[msg.sender] > 0) revert AlreadyMember();

        // check if member has to pay a join fee
        if (group.joinFee > 0) {
            if (msg.value < group.joinFee) revert InsufficientJoinFee();

            SafeTransferLib.safeTransferETH(group.vault, msg.value);

            emit JoinFeePaid(_id, msg.sender, group.joinFee);
        }

        group.memberId++;
        group.members[group.memberId] = msg.sender;
        group.memberIds[msg.sender] = group.memberId;

        emit GroupJoined(_id, msg.sender);
    }

    // Make contribution to the current round
    function contribute(uint256 _id) external payable override {
        Group storage group = groups[_id];

        if (group.id == 0) revert GroupNotFound();
        if (!group.isActive) revert GroupInactive();

        uint256 currentRound = group.currentRound;
        uint256 memberId = group.memberIds[msg.sender];

        if (memberId == 0) revert NotMember();

        if (group.roundContributions[currentRound][memberId] > 0)
            revert AlreadyContributed();

        if (msg.value < group.contributionAmount)
            revert InsufficientContribution();

        SafeTransferLib.safeTransferETH(group.vault, msg.value);
        group.roundBalance[currentRound] += msg.value;

        group.roundContributions[currentRound][memberId] = msg.value;

        emit Contribution(_id, msg.sender, msg.value);
    }

    function distribute(
        uint256 _id
    ) external payable override onlyCreator(_id) {
        Group storage group = groups[_id];

        if (group.id == 0) revert GroupNotFound();
        if (!group.isActive) revert GroupInactive();
        if (group.currentRound == group.maxMembers) revert AllRoundsPaid();

        uint256 currentRound = group.currentRound;
        uint256 payoutMemberId = group.roundPayout[currentRound];
        uint256 roundBalance = group.roundBalance[currentRound];
        address payoutMember = group.members[payoutMemberId];

        if (payoutMemberId == 0) revert InvalidPayoutMember();

        if (group.roundPaid[currentRound][payoutMemberId]) revert AlreadyPaid();
        uint256 totalContributions = group.memberId * group.contributionAmount;

        if (roundBalance != totalContributions)
            revert InsuffientPayoutAmount(roundBalance, totalContributions);

        SafeTransferLib.safeTransferETH(payoutMember, roundBalance);

        group.roundPaid[currentRound][payoutMemberId] = true;

        group.roundBalance[currentRound] = 0;
        group.currentRound++;

        emit Payout(_id, payoutMember, roundBalance);
    }

    function setGroupInactive(uint256 _id) external override onlyCreator(_id) {
        Group storage group = groups[_id];

        if (group.id == 0) revert GroupNotFound();

        group.isActive = false;
    }

    function setGroupActive(uint256 _id) external override onlyCreator(_id) {
        Group storage group = groups[_id];

        if (group.id == 0) revert GroupNotFound();

        group.isActive = true;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}
