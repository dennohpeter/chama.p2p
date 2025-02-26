// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IChama {
    event GroupCreated(
        uint256 id,
        string name,
        address creator,
        uint256 maxMembers
    );

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
        uint256 currentRound;
        // currentRound => memberId => address
        mapping(uint256 => mapping(uint256 => address)) roundMembers;
        // currentRound => memberId => address
        mapping(uint256 => mapping(uint256 => uint256)) roundContributions;
        // currentRound => memberId => address
        mapping(uint256 => mapping(uint256 => uint256)) roundPayouts;
        // currentRound => memberId => address
        mapping(uint256 => mapping(uint256 => bool)) roundPaid;
    }

    // function createGroup(
    //     string memory _name,
    //     uint256 _maxMembers
    // ) external returns (uint256);

    // function joinGroup(uint256 _id) external;

    error GroupNotFound();
    error GroupFull();
    error AlreadyMember();
    error NotMember();
}
