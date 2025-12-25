// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/
import {Test} from "forge-std/Test.sol";
import {Staking, Staking__ZeroAmount, Staking__InsufficientBalance} from "../../src/Staking.sol";
import {MyToken} from "../../src/MyToken.sol";

/*//////////////////////////////////////////////////////////////
                            TEST CONTRACT
//////////////////////////////////////////////////////////////*/

/// @title Staking Contract Test - Step 1
/// @author Tmeech
contract StakingTest is Test {
    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    Staking staking;
    MyToken token;
    address owner = address(1);
    address user = address(2);
    uint256 public constant STAKE_AMOUNT = 1e18;

    uint256 rewardRate = 1; // 1 token per second per staked token for testing

    /*//////////////////////////////////////////////////////////////
                              SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        // Deploy token
        vm.prank(owner);
        token = new MyToken();

        // Mint tokens to user
        vm.prank(owner);
        token.mint(user, STAKE_AMOUNT);

        // Deploy staking contract
        vm.prank(owner);
        staking = new Staking(address(token), rewardRate);

        // Approve staking contract
        vm.prank(user);
        token.approve(address(staking), STAKE_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                               TESTS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                        STEP 1: STAKE
    //////////////////////////////////////////////////////////////*/

    function test_UserCanStake() public {
        // Arrange
        vm.prank(user);
        uint256 stakeAmount = STAKE_AMOUNT;

        // Act
        // vm.prank(user);
        staking.stake(stakeAmount);

        // Assert
        uint256 staked = staking.getStaked(user);
        assertEq(staked, stakeAmount);
    }

    function test_StakeZeroReverts() public {
        // Arrange
        vm.prank(user);
        uint256 stakeAmount = 0;

        // Act + Assert
        // vm.prank(user);
        vm.expectRevert(Staking__ZeroAmount.selector);
        staking.stake(stakeAmount);
    }

    /*//////////////////////////////////////////////////////////////
                       STEP 2: UNSTAKE + REWARDS
    //////////////////////////////////////////////////////////////*/

    function test_UserCanUnstake() public {
        // Arrange
        vm.prank(user);
        uint256 stakeAmount = STAKE_AMOUNT;
        staking.stake(stakeAmount);

        // Act
        vm.prank(user);
        staking.unstake(stakeAmount);

        // Assert
        uint256 staked = staking.getStaked(user);
        assertEq(staked, 0); // user should have 0 staked after unstaking
    }

    function test_UnstakeMoreThanStakedReverts() public {
        // Arrange
        vm.prank(user);
        uint256 stakeAmount = STAKE_AMOUNT;
        staking.stake(stakeAmount);

        uint256 unstakeAmount = 2e18; // more than staked

        // Act + Assert
        vm.prank(user);
        vm.expectRevert(Staking__InsufficientBalance.selector);
        staking.unstake(unstakeAmount);
    }

    function test_RewardsAccumulateOverTime() public {
        // Arrange
        vm.prank(user);
        uint256 stakeAmount = STAKE_AMOUNT;
        staking.stake(stakeAmount);

        // Move time forward by 100 seconds
        vm.warp(block.timestamp + 100);

        // Act
        uint256 pendingRewards = staking.getPendingRewards(user);

        // Assert
        // rewardRate = 1, staked = 1e18, 100 seconds => 100 * 1e18
        assertEq(pendingRewards, 100 * STAKE_AMOUNT);
    }

    function test_ClaimRewards() public {
        // Arrange
        vm.prank(user);
        uint256 stakeAmount = STAKE_AMOUNT;
        staking.stake(stakeAmount);

        // Warp time 50 seconds
        vm.warp(block.timestamp + 50);

        // FUND THE STAKING CONTRACT FOR REWARDS
        vm.prank(owner);
        token.mint(address(staking), 1000 ether);

        // Act
        vm.prank(user);
        staking.claimRewards();

        // Assert
        uint256 pending = staking.getPendingRewards(user);
        assertEq(pending, 0); // rewards should reset after claiming
    }
}
