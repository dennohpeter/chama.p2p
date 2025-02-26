// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IChama} from "@contracts/IChama.sol";

contract Chama is IChama {
    uint256 public groupId;

    mapping(uint256 => Group) public groups;

    constructor() {}

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

        // check if member has already joined
        for (uint256 i = 1; i <= group.memberId; i++) {
            if (group.members[i] == msg.sender) revert AlreadyMember();
        }

        // check if member has to pay a join fee
        if (group.joinFee > 0) {
            if (msg.value < group.joinFee) revert InsufficientJoinFee();

            payable(group.vault).transfer(msg.value);

            emit JoinFeePaid(_id, msg.sender, group.joinFee);
        }

        group.memberId++;
        group.members[group.memberId] = msg.sender;

        emit GroupJoined(_id, msg.sender);
    }

    function contribute(uint256 _id) external payable override {}

    function payout(PayoutParams memory _group) external override {}

    function distribute(uint256 _id) external override {}
}
