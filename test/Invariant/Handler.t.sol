// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Layout of Contract:
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

/// @title Handler
/// @author Tmeech
/// @notice Fuzz handler simulating random user interactions with Staking
/// @dev This contract is used by invariant tests to call staking functions unpredictably
contract Handler is Test {
    // --------------------------------------------------
    // State variables
    // --------------------------------------------------

    Staking public staking;
    MyToken public token;
    uint256 public constant MINT_AMOUNT = 100e18;
    uint256 public constant BOUND_AMOUNT_MIN = 1e18;

    address[] public users;

    mapping(address => uint256) public userStaked;

    // --------------------------------------------------
    // Constructor
    // --------------------------------------------------

    /// @param _staking Address of staking contract
    /// @param _token Address of ERC20 staking token
    constructor(Staking _staking, MyToken _token) {
        staking = _staking;
        token = _token;

        // Pre-generate a list of test users
        for (uint256 i = 1; i <= 5; i++) {
            address user = address(uint160(i));
            users.push(user);

            // Give each user tokens
            vm.prank(address(1));
            token.mint(user, MINT_AMOUNT);

            // Approve staking contract
            vm.prank(user);
            token.approve(address(staking), type(uint256).max);
        }
    }

    // --------------------------------------------------
    // External Functions (Actions for fuzzing)
    // --------------------------------------------------

    /// @notice Fuzz action: stake tokens
    /// @dev Caps amounts so fuzzing doesn't attempt impossible values
    function stake(uint256 userIndex, uint256 amount) external {
        address user = users[userIndex % users.length];
        amount = bound(amount, BOUND_AMOUNT_MIN, MINT_AMOUNT); // between 1–10 tokens

        vm.startPrank(user);
        staking.stake(amount);
        vm.stopPrank();

        userStaked[user] += amount;
    }

    /// @notice Fuzz action: unstake tokens
    function unstake(uint256 userIndex, uint256 amount) external {
        address user = users[userIndex % users.length];

        uint256 maxAllowed = userStaked[user];
        if (maxAllowed == 0) return; // skip if nothing staked

        amount = bound(amount, BOUND_AMOUNT_MIN, maxAllowed);

        vm.startPrank(user);
        staking.unstake(amount);
        vm.stopPrank();

        userStaked[user] -= amount;
    }

    /// @notice Fuzz action: claim rewards
    function claimRewards(uint256 userIndex) external {
        address user = users[userIndex % users.length];

        vm.startPrank(user);
        staking.claimRewards();
        vm.stopPrank();
    }

    // --------------------------------------------------
    // View helpers for invariants
    // --------------------------------------------------

    function totalStakedByUsers() external view returns (uint256 total) {
        for (uint256 i = 0; i < users.length; i++) {
            total += userStaked[users[i]];
        }
    }

    function getUsers() external view returns (address[] memory) {
        return users;
    }
}
