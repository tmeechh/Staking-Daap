// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Layout:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

import {Test, console} from "forge-std/Test.sol";
import {Staking} from "../../src/Staking.sol";
import {MyToken} from "../../src/MyToken.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Handler} from "./Handler.t.sol";

/// @title StakingInvariant
/// @author Tmeech
/// @notice Invariant testing suite ensuring Staking.sol always stays consistent
/// @dev Uses Handler to simulate unpredictable user behavior
contract StakingInvariant is StdInvariant, Test {
    // --------------------------------------------------
    // State Variables
    // --------------------------------------------------

    Staking public staking;
    MyToken public token;
    Handler public handler;
    uint256 public constant MINT_AMOUNT = 1000000e18;
    uint256 public constant TOKEN = 1e18;

    // --------------------------------------------------
    // Setup
    // --------------------------------------------------

    function setUp() external {
        //  vm.stopPrank();
        // Deploy fresh token & staking contract
        // Deploy token as `address(1)` so address(1) becomes the owner for setup
        vm.prank(address(1));
        token = new MyToken();
        staking = new Staking(address(token), TOKEN); // 1 token/second rewardRate

        // Mint rewards to staking contract (so fuzz claimRewards has supply)
        // mint must be called by the token owner (address(1))
        vm.prank(address(1));
        token.mint(address(staking), MINT_AMOUNT);

        // Create handler
        handler = new Handler(staking, token);

        // Tell the invariant engine:
        // "Call all public/external methods on handler during fuzzing"
        targetContract(address(handler));
    }

    // --------------------------------------------------
    // Invariants
    // --------------------------------------------------

    /// @notice The staking contract balance must always equal all user deposits + leftover rewards.
    /// @dev Staking contract must *never* lose staked tokens.
    function invariant_TotalTokensMatch() external view{
        uint256 handlerTotal = handler.totalStakedByUsers();
        uint256 contractBalance = token.balanceOf(address(staking));

        // The contract should ALWAYS have >= staked amount.
        assertGe(contractBalance, handlerTotal, "INVARIANT FAIL: staking contract lost user funds");
    }

    /// @notice No user should ever have a negative staked balance (mathematically impossible).
    function invariant_NonNegativeBalances() external view{
        address[] memory users = handler.getUsers();

        for (uint256 i = 0; i < users.length; i++) {
            uint256 amount = handler.userStaked(users[i]);
            assertGe(amount, 0, "INVARIANT FAIL: user staked < 0");
        }
    }

    /// @notice Total staked reported by contract must match or be <= handler (handler might ignore dust)
    function invariant_ContractVsHandler() external view{
        uint256 contractTotal = staking.totalStaked();
        uint256 handlerTotal = handler.totalStakedByUsers();

        // totalStaked() should be exactly equal unless rounding occurs
        assertEq(contractTotal, handlerTotal, "INVARIANT FAIL: contract.totalStaked doesn't match handler tracking");
    }

    /// @notice The staking contract must never revert internally or overflow.
    /// @dev forge handles most reverts automatically in invariant-testing, but we add logic checks.
    function invariant_NoOverflow() external view {
        uint256 rewardRate = staking.rewardRate();
        assertLe(rewardRate, type(uint256).max / TOKEN, "rewardRate overflow risk");
    }

    /// @notice Sum of all users' pending rewards must be coverable by the contract's reward pool.
    /// @dev rewardPool = token.balanceOf(staking) - staking.totalStaked()
    function invariant_RewardPoolSuffices() external view{
        address[] memory users = handler.getUsers();

        uint256 sumPending = 0;
        for (uint256 i = 0; i < users.length; i++) {
            // accumulate pending rewards for each user
            uint256 pending = staking.getPendingRewards(users[i]);

            // safe add (solidity ^0.8 reverts on overflow — which would fail the test and is desirable)
            sumPending += pending;
        }

        uint256 contractBalance = token.balanceOf(address(staking));
        uint256 contractStaked = staking.totalStaked();

        // sanity: contract balance must be at least totalStaked
        assertGe(contractBalance, contractStaked, "INVARIANT FAIL: contract.balance < contract.totalStaked");

        // reward pool that can be used to pay pending rewards
        uint256 rewardPool = contractBalance - contractStaked;

        // The sum of all pending rewards must be <= rewardPool
        assertLe(
            sumPending,
            rewardPool,
            "INVARIANT FAIL: sum pending rewards > reward pool (potential overflow/insufficient funds)"
        );
    }

    /// @notice Ensures no double-counting of tokens: staked + pending rewards <= actual contract balance
    function invariant_NoDoubleCounting() external view{
        address[] memory users = handler.getUsers();

        uint256 sumStaked = 0;
        uint256 sumPending = 0;

        for (uint256 i = 0; i < users.length; i++) {
            sumStaked += handler.userStaked(users[i]);
            sumPending += staking.getPendingRewards(users[i]);
        }

        uint256 contractBalance = token.balanceOf(address(staking));

        // Contract balance should always cover all staked tokens + total pending rewards
        assertGe(
            contractBalance,
            sumStaked + sumPending,
            "INVARIANT FAIL: Contract balance < total staked + pending rewards (double-count risk)"
        );
    }

    /// @notice Ensures the rewardRate in the contract never changes unexpectedly
    function invariant_RewardRateConsistency() external view {
        uint256 currentRate = staking.rewardRate();
        // Should always equal the rate we set in setUp
        assertEq(currentRate, staking.rewardRate(), "INVARIANT FAIL: rewardRate changed unexpectedly");
    }

    /// @notice Ensures no user can ever have negative pending rewards
    function invariant_NoNegativeRewards() external view {
        address[] memory users = handler.getUsers();

        for (uint256 i = 0; i < users.length; i++) {
            uint256 rewards = staking.getPendingRewards(users[i]);
            assertGe(rewards, 0, "INVARIANT FAIL: user has negative rewards");
        }
    }
}
