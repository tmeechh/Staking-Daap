// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";
import {Staking} from "../src/Staking.sol";

/// @notice A Sepolia-ready, in-repo interaction script.
/// - No private keys are embedded in this file.
/// - Run with a local keystore / foundry signer:
///   forge script script/InteractSepolia.s.sol:InteractSepolia --rpc-url $SEPOLIA_RPC_URL --keystore ~/.foundry/keystores/raffletest --broadcast
contract InteractSepolia is Script {
    function run() external {
        // ------------------------------------------------------------------
        // Fill / confirm: these are the addresses created by your successful
        // deploy on Sepolia (from your logs). Do NOT change unless you
        // intentionally want to point to other addresses.
        // ------------------------------------------------------------------
        address tokenAddr = 0x928dA4e13275be33aEb924986cC210e602bd7eed;
        address stakingAddr = 0xaE21C2Fd491546cA74D9028749cC5C6Ce49e744D;

        // ------------------------------------------------------------------
        // Safety toggles (set true for the action you want to run). Only
        // enable one at a time to avoid accidental multi-step runs.
        // ------------------------------------------------------------------
        bool DO_PRINT_BALANCES = true; // prints token balance & staked amount
        bool DO_APPROVE = false;       // approve staking contract to spend tokens
        bool DO_STAKE = false;         // stake tokens
        bool DO_CLAIM = false;         // claim rewards
        bool DO_UNSTAKE = false;       // unstake tokens
        bool DO_MINT = false;          // only allowed if signer==token owner

        // Amounts — set exact wei values you want to use for operations
        // (no random figures). Adjust to your needs before running.
        uint256 MINT_AMOUNT = 100 * 1e18;   // 100 MTK, only allowed if signer==token owner
        uint256 APPROVE_AMOUNT = 100 * 1e18; // allowance for staking contract
        uint256 STAKE_AMOUNT = 100 * 1e18;   // amount to stake
        uint256 UNSTAKE_AMOUNT = 50 * 1e18;  // amount to unstake

        // Always use a keystore / signer rather than embedding private keys
        vm.startBroadcast();
        console.log("Active signer:", msg.sender);

        MyToken token = MyToken(tokenAddr);
        Staking staking = Staking(stakingAddr);

        if (DO_PRINT_BALANCES) {
            console.log("--- Balances for signer:");
            console.log("Token balance:", token.balanceOf(msg.sender));
            console.log("Staked amount:", staking.getStaked(msg.sender));
        }

        if (DO_APPROVE) {
            console.log("Approving staking contract to spend:", APPROVE_AMOUNT);
            token.approve(stakingAddr, APPROVE_AMOUNT);
            console.log("Approved.");
        }

        if (DO_STAKE) {
            console.log("Staking:", STAKE_AMOUNT);
            staking.stake(STAKE_AMOUNT);
            console.log("Staked.");
        }

        if (DO_CLAIM) {
            console.log("Claiming rewards for signer...");
            staking.claimRewards();
            console.log("Claim executed.");
        }

        if (DO_UNSTAKE) {
            console.log("Unstaking:", UNSTAKE_AMOUNT);
            staking.unstake(UNSTAKE_AMOUNT);
            console.log("Unstaked.");
        }

        if (DO_MINT) {
            // Mint is owner-only. Check and fail early if caller isn't owner.
            address owner = token.i_owner();
            console.log("Token owner:", owner);
            if (owner != msg.sender) {
                revert("Only token owner may mint - switch keystore to the deployer");
            }
            console.log("Minting:", MINT_AMOUNT, "to signer...");
            token.mint(msg.sender, MINT_AMOUNT);
            console.log("Mint successful.");
        }

        vm.stopBroadcast();
    }
}
