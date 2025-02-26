// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

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
    error NotEnoughBalance();
    error InsufficientJoinFee();
    error InsufficientContribution();
    error AlreadyContributed();

    event GroupCreated(uint256 indexed id, string name, address creator);
    event GroupJoined(uint256 indexed id, address member);
    event JoinFeePaid(uint256 indexed id, address member, uint256 amount);
    event Contribution(uint256 indexed id, address member, uint256 amount);
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
        // currentRound => memberId => address
        mapping(uint256 => mapping(uint256 => uint256)) roundContributions;
        // currentRound => memberId => address
        mapping(uint256 => mapping(uint256 => uint256)) roundPayouts;
        // currentRound => memberId => address
        mapping(uint256 => mapping(uint256 => bool)) roundPaid;
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

    struct PayoutParams {
        uint256 groupId;
    }

    struct Member {
        uint256 id;
        address member;
        uint256 contribution;
        uint256 payout;
        bool paid;
    }
    function createGroup(
        CreateGroupParams memory _group
    ) external returns (uint256);

    function getGroup(uint256 _id) external view returns (GroupParams memory);

    function joinGroup(uint256 _id) external payable;

    function contribute(uint256 _id) external payable;

    function payout(PayoutParams memory _group) external;

    function distribute(uint256 _id) external;
}
