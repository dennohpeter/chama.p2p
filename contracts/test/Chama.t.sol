// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Chama} from "@contracts/Chama.sol";
import {IChama} from "@contracts/IChama.sol";

contract ChamaTest is Test {
    Chama chama;
    address public DEFAULT_VAULT = makeAddr("default vault");

    function setUp() external {
        chama = new Chama();
    }

    function testCreateGroup() external {
        uint256 groupId = chama.createGroup(_defaultGroup());

        assertEq(groupId, 1);

        assertEq(chama.groupId(), 1);

        IChama.GroupParams memory params = chama.getGroup(groupId);
        {
            assertEq(params.id, 1);
            assertEq(params.name, "Test Chama");
            assertEq(params.description, "Test Chama Description");
            assertEq(params.vault, DEFAULT_VAULT);
            assertEq(params.cycleDays, 10);
            assertEq(params.maxMembers, 4);
            assertEq(params.contributionAmount, 10);
            assertEq(params.joinFee, 0);
            assertEq(params.lateFee, 0);
            assertEq(params.currentRound, 1);
        }
    }

    function testJoinGroup() external {
        uint256 groupId = chama.createGroup(_defaultGroup());

        uint256 members = 3;
        _addToGroup(groupId, members);

        IChama.GroupParams memory params = chama.getGroup(groupId);
        {
            assertEq(params.memberId, members + 1);
        }
    }

    function testContribute() external {
        uint256 groupId = chama.createGroup(_defaultGroup());

        IChama.GroupParams memory group = chama.getGroup(groupId);

        uint256 contributionAmount = group.contributionAmount;

        _contribute(groupId, contributionAmount);

        uint256 roundBalance = chama.roundBalance(groupId, group.currentRound);
        {
            assertEq(roundBalance, contributionAmount);
        }

        // vault balance should be equal to the contribution amount
        assertEq(address(chama).balance, contributionAmount);

        console.log("Round Balance: ", roundBalance);
    }

    function testSetGroupInactive() external {
        uint256 groupId = chama.createGroup(_defaultGroup());

        chama.setGroupInactive(groupId);

        IChama.GroupParams memory group = chama.getGroup(groupId);
        {
            assertEq(group.isActive, false);
        }
    }

    function testSetGroupActive() external {
        uint256 groupId = chama.createGroup(_defaultGroup());

        chama.setGroupInactive(groupId);

        IChama.GroupParams memory group = chama.getGroup(groupId);
        {
            assertEq(group.isActive, false);
        }

        chama.setGroupActive(groupId);

        group = chama.getGroup(groupId);
        {
            assertEq(group.isActive, true);
        }
    }

    function testSetPayoutOrder() external {
        uint256 groupId = chama.createGroup(_defaultGroup());

        uint256 members = 3;
        _addToGroup(groupId, members);

        uint256[] memory _rounds = new uint256[](members + 1);
        _rounds[0] = 1;
        _rounds[1] = 2;
        _rounds[2] = 3;
        _rounds[3] = 4;

        address[] memory _members = new address[](members + 1);
        _members[0] = address(this);
        {
            for (uint256 i = 0; i < members; i++) {
                _members[i + 1] = makeAddr(string(abi.encode(i)));
            }
        }

        chama.setPayoutOrder(groupId, _rounds, _members);
    }

    function testDistribute() external {
        uint256 groupId = chama.createGroup(_defaultGroup());

        uint256 members = 3;
        _addToGroup(groupId, members);

        // set payout order
        {
            uint256[] memory _rounds = new uint256[](members + 1);
            _rounds[0] = 2;
            _rounds[1] = 1;
            _rounds[2] = 3;
            _rounds[3] = 4;

            address[] memory _members = new address[](members + 1);
            _members[0] = address(this);
            for (uint256 i = 0; i < members; i++) {
                _members[i + 1] = makeAddr(string(abi.encode(i)));
            }

            chama.setPayoutOrder(groupId, _rounds, _members);
        }

        IChama.GroupParams memory group = chama.getGroup(groupId);

        uint256 contributionAmount = group.contributionAmount;

        //  all members contribute
        {
            // creator contributes
            _contribute(groupId, contributionAmount);

            for (uint256 i = 0; i < members; i++) {
                address member = makeAddr(string(abi.encode(i)));

                vm.deal(member, 100);

                vm.startPrank(member);
                _contribute(groupId, contributionAmount);
                vm.stopPrank();
            }
        }

        // unstake i.e multisig vault sends funds to our smart contract
        // this is done by the vault owner
        // {
        //     vm.startPrank(DEFAULT_VAULT);
        //     console.log("Vault Balance: ", address(DEFAULT_VAULT).balance);
        //     uint256 pot = contributionAmount * (members + 1);

        //     (bool sent, ) = address(chama).call{value: pot}("");

        //     require(sent, "Failed to send Ether");

        //     vm.stopPrank();
        // }

        chama.distribute(groupId);

        uint256 roundBalance = chama.roundBalance(groupId, group.currentRound);
        {
            assertEq(roundBalance, 0);
        }

        // vault balance should be equal to the contribution amount
        assertEq(address(DEFAULT_VAULT).balance, 0);

        IChama.GroupParams memory _params = chama.getGroup(groupId);
        {
            assertEq(_params.currentRound, 2);
        }

        console.log("Round Balance: ", roundBalance);

        IChama.MemberPayout[] memory payout = chama.payouts(groupId);
        {
            for (uint256 i = 0; i < payout.length; i++) {
                console.log("---");
                console.log("Member: ", payout[i].member);
                console.log("Amount: ", payout[i].amount);
                console.log("memberId: ", payout[i].memberId);
                console.log("Round: ", payout[i].round);
                console.log("Paid: ", payout[i].paid);
            }
        }
    }

    function _defaultGroup()
        internal
        view
        returns (IChama.CreateGroupParams memory)
    {
        return
            IChama.CreateGroupParams({
                name: "Test Chama",
                description: "Test Chama Description",
                vault: DEFAULT_VAULT,
                cycleDays: 10,
                maxMembers: 4,
                contributionAmount: 10,
                joinFee: 0,
                lateFee: 0
            });
    }

    function _contribute(uint256 _groupId, uint256 _amount) internal {
        chama.contribute{value: _amount}(_groupId);
    }

    function _addToGroup(uint256 _groupId, uint256 numMembers) internal {
        for (uint256 i = 0; i < numMembers; i++) {
            vm.startPrank(makeAddr(string(abi.encode(i))));
            chama.joinGroup(_groupId);
            vm.stopPrank();
        }
    }
}
