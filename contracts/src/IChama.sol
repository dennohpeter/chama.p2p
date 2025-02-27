// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IChama {
    error MaxMembersZero();
    error CycleDaysZero();
    error ContributionAmountZero();
    error GroupNotFound();
    error GroupFull();
    error GroupInactive();
    error GroupStarted();
    error AlreadyMember();
    error NotMember();
    error NotCreator();
    error InsufficientJoinFee();
    error InsufficientContribution();
    error InsuffientPayoutAmount(uint256 balance, uint256 payout);
    error AlreadyContributed();
    error AllRoundsPaid();
    error AlreadyPaid();
    error InvalidPayoutMember();
    error ExcessContribution(uint256 required, uint256 excess);
    error InvalidMembers();
    error RoundsMembersMismatch();
    error DuplicatePayoutMember(address member);
    error UknownMember(address member);

    event GroupCreated(uint256 indexed id, string name, address creator);
    event GroupJoined(uint256 indexed id, address member);
    event JoinFeePaid(uint256 indexed id, address member, uint256 amount);
    event Contributed(uint256 indexed id, address member, uint256 amount);
    event Payout(uint256 indexed id, address member, uint256 amount);

    struct Group {
        uint256 id;
        // TODO: save metadata in ipfs
        string name;
        string description;
        //
        bool isActive;
        address creator;
        address vault;
        //
        uint256 memberId;
        uint256 cycleDays;
        uint256 maxMembers;
        uint256 contributionAmount;
        uint256 joinFee;
        uint256 lateFee;
        uint256 currentRound;
        // currentRound => balance
        mapping(uint256 => uint256) roundBalance;
        // memberId => address
        mapping(uint256 => address) members;
        // address => memberId
        mapping(address => uint256) memberIds;
        // currentRound => memberId => contribution
        mapping(uint256 => mapping(uint256 => uint256)) roundContributions;
        // currentRound => payoutMemberId
        mapping(uint256 => uint256) roundPayout;
        // payoutMemberId => currentRound
        mapping(uint256 => uint256) memberIdRoundPayout;
        // address => round
        mapping(address => uint256) roundPaid;
    }

    struct CreateGroupParams {
        string name;
        string description;
        address vault;
        uint256 maxMembers;
        uint256 cycleDays;
        uint256 contributionAmount;
        uint256 joinFee;
        uint256 lateFee;
    }

    struct GroupParams {
        uint256 id;
        string name;
        string description;
        bool isActive;
        address creator;
        address vault;
        uint256 memberId;
        uint256 cycleDays;
        uint256 maxMembers;
        uint256 contributionAmount;
        uint256 joinFee;
        uint256 lateFee;
        uint256 currentRound;
    }

    struct Member {
        uint256 id;
        address member;
        uint256 groupId;
    }

    struct Contribution {
        uint256 memberId;
        address member;
        uint256 amount;
        uint256 round;
    }

    struct MemberPayout {
        uint256 memberId;
        address member;
        uint256 amount;
        uint256 round;
        bool paid;
    }

    function createGroup(
        CreateGroupParams memory _group
    ) external returns (uint256);

    function getGroup(uint256 _id) external view returns (GroupParams memory);

    function joinGroup(uint256 _id) external payable;

    function contribute(uint256 _id) external payable;

    function distribute(uint256 _id) external payable;

    function setGroupInactive(uint256 _id) external;

    function setGroupActive(uint256 _id) external;

    function contributions(
        uint256 _id,
        uint256 _round
    ) external view returns (Contribution[] memory);

    function members(uint256 _id) external view returns (Member[] memory);

    function roundBalance(
        uint256 _id,
        uint256 _round
    ) external view returns (uint256);

    function setPayoutOrder(
        uint256 _groupId,
        uint256[] memory _rounds,
        address[] memory _members
    ) external;

    function payouts(uint256 _id) external view returns (MemberPayout[] memory);
}
