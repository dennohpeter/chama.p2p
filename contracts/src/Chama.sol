// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IChama} from "@contracts/IChama.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";

contract Chama is IChama {
    uint256 public groupId;

    mapping(uint256 => Group) public groups;

    mapping(uint256 => uint256) public balances;

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

        {
            // scoped to avoid stack too deep error
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
            group.currentRound = 1;

            group.members[group.memberId] = msg.sender;
            group.memberIds[msg.sender] = group.memberId;
        }

        emit GroupCreated(groupId, _group.name, msg.sender);

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
        if (group.currentRound > 1) revert GroupStarted();
        if (group.memberIds[msg.sender] > 0) revert AlreadyMember();

        // check if member has to pay a join fee
        if (group.joinFee > 0) {
            if (msg.value < group.joinFee) revert InsufficientJoinFee();

            // SafeTransferLib.safeTransferETH(group.vault, msg.value);
            balances[groupId] += msg.value;

            emit JoinFeePaid(_id, msg.sender, group.joinFee);
        }

        group.memberId += 1;
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

        if (msg.value > group.contributionAmount)
            revert ExcessContribution(group.contributionAmount, msg.value);

        // SafeTransferLib.safeTransferETH(group.vault, msg.value);
        group.roundBalance[currentRound] += msg.value;

        balances[groupId] += msg.value;

        group.roundContributions[currentRound][memberId] = msg.value;

        emit Contributed(_id, msg.sender, msg.value);
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
        uint256 roundBalance_ = group.roundBalance[currentRound];
        address payoutMember = group.members[payoutMemberId];

        if (payoutMemberId == 0) revert InvalidPayoutMember();

        if (group.roundPaid[payoutMember] > 0) revert AlreadyPaid();
        uint256 totalContributions = group.memberId * group.contributionAmount;

        if (roundBalance_ != totalContributions) {
            revert InsuffientPayoutAmount(roundBalance_, totalContributions);
        }

        SafeTransferLib.safeTransferETH(payoutMember, roundBalance_);

        group.roundPaid[payoutMember] = currentRound;

        group.roundBalance[currentRound] = 0;
        group.currentRound++;

        emit Payout(_id, payoutMember, roundBalance_);
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

    function contributions(
        uint256 _id,
        uint256 _round
    ) external view returns (Contribution[] memory _contributions) {
        Group storage group = groups[_id];

        if (group.id == 0) revert GroupNotFound();

        _contributions = new Contribution[](group.memberId);

        for (uint256 memberId; memberId < group.memberId; memberId++) {
            uint256 contribution = group.roundContributions[_round][
                memberId + 1
            ];

            _contributions[memberId] = Contribution({
                memberId: memberId,
                member: group.members[memberId],
                amount: contribution,
                round: _round
            });
        }
    }

    function members(
        uint256 _id
    ) external view returns (Member[] memory _members) {
        Group storage group = groups[_id];

        if (group.id == 0) revert GroupNotFound();

        _members = new Member[](group.memberId);

        for (uint256 memberId = 1; memberId <= group.memberId; memberId++) {
            _members[memberId] = Member({
                id: memberId,
                member: group.members[memberId],
                groupId: _id
            });
        }
    }

    function roundBalance(
        uint256 _id,
        uint256 _round
    ) external view returns (uint256) {
        Group storage group = groups[_id];

        if (group.id == 0) revert GroupNotFound();

        return group.roundBalance[_round];
    }

    function setPayoutOrder(
        uint256 _id,
        uint256[] memory _rounds,
        address[] memory _members
    ) external override onlyCreator(_id) {
        Group storage group = groups[_id];

        if (group.id == 0) revert GroupNotFound();
        if (!group.isActive) revert GroupInactive();
        if (group.currentRound == group.maxMembers) revert AllRoundsPaid();
        if (group.memberId != _members.length) revert InvalidMembers();
        if (_rounds.length != _members.length) revert RoundsMembersMismatch();
        if (group.currentRound > 1) revert GroupStarted();

        for (uint256 i; i < _members.length; i++) {
            address member = _members[i];
            uint256 memberId = group.memberIds[member];
            uint _round = _rounds[i];

            if (memberId == 0) revert UknownMember(member);

            group.roundPayout[_round] = memberId;
            group.memberIdRoundPayout[memberId] = _round;
        }
    }

    function payouts(
        uint256 _id
    ) external view override returns (MemberPayout[] memory _payouts) {
        Group storage group = groups[_id];

        if (group.id == 0) revert GroupNotFound();

        _payouts = new MemberPayout[](group.memberId);

        uint256 payout = group.contributionAmount * group.memberId;

        for (uint256 memberId = 1; memberId < group.memberId; memberId++) {
            address member = group.members[memberId];

            bool paid = group.roundPaid[member] > 0;
            _payouts[memberId - 1] = MemberPayout({
                memberId: memberId,
                member: member,
                amount: payout,
                round: group.memberIdRoundPayout[memberId],
                paid: paid
            });
        }
    }

    receive() external payable {}
}
