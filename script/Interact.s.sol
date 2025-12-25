// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";
import {Staking} from "../src/Staking.sol";

/// @notice Small utility script to perform common interactions with the deployed
/// token + staking instances. This is convenient for testing on Sepolia (or
/// other networks) without writing ad-hoc CLI calls.
contract Interact is Script {
    function run() external {
        // ===== CONFIG (edit values here; no PRIVATE_KEY in code) =====
        // IMPORTANT: do NOT include your private key in source control. Use
        // `forge script --keystore <name>` (recommended) or interactive signing.
        //
        // Fill the values below before running this script (replace the
        // example placeholders). These are all in-file (not read from env):
        // - TOKEN_ADDR   : deployed token address (from `forge script` output)
        // - STAKING_ADDR : deployed staking address (from `forge script` output)
        // - ACTION       : mint | approve | stake | claim | unstake | balance
        // - AMOUNT       : optional amount in wei (uint256) used by some actions
        // - TO           : (optional) target address for mint; defaults to tx sender
        // - TARGET       : (optional) address to query balances for; defaults to tx sender
        //
        // Where to get these values (exact places to look):
        // * TOKEN_ADDR / STAKING_ADDR: after you deploy, Foundry prints the addresses
        //   and saves broadcasts under: broadcast/<scriptName>/<chain>/run-<timestamp>.json
        //   Example (inspect file):
        //     $ jq '.[0].transaction' broadcast/Deploy.s.sol/sepolia/run-latest.json
        //   Or open the `run-latest.json` file and search for "contractAddress".
        //   On Sepolia you can also confirm on Etherscan — that page shows the deployed
        //   contract address (and after verification will show the ABI and source).
        // * ACTION / AMOUNT / TO / TARGET: choose based on what you want to run.
        //
        // Example (replace placeholders with real values before running):
        string memory action = "stake"; // e.g. "mint", "approve", "stake", "claim", "unstake", "balance"
        address tokenAddr = 0x0000000000000000000000000000000000000000; // <-- REPLACE
        address stakingAddr = 0x0000000000000000000000000000000000000000; // <-- REPLACE
        uint256 amount = 0; // optional: set in wei (eg 1e18 for 1 token)
        address to = address(0); // optional: used by `mint`
        address target = address(0); // optional: used by `balance`

        // Ensure user has set useful values
        require(tokenAddr != address(0) && stakingAddr != address(0), "set TOKEN_ADDR and STAKING_ADDR in the script before running");

        MyToken token = MyToken(tokenAddr);
        Staking staking = Staking(stakingAddr);

        // Use keystore / built-in signer instead of embedding private keys.
        // Recommended: run with a foundry keystore so private keys stay off disk
        // in your repo:
        //   forge script script/Interact.s.sol:Interact --rpc-url $SEPOLIA_RPC_URL --keystore raffletest --broadcast
        // or use your shell to get the address from your local keystore file first:
        //   $ cat ~/.foundry/keystores/raffletest   # look for `"address": "0x..."`
        // At run-time we'll print the active signer address so you can confirm.
        vm.startBroadcast();
        console.log("Signer/Tx sender:", msg.sender);

        if (keccak256(bytes(action)) == keccak256(bytes("mint"))) {
            if (amount == 0) revert("AMOUNT must be set for mint action");
            address recipient = to == address(0) ? msg.sender : to;
            token.mint(recipient, amount);
            console.log("Minted", amount, "to", recipient);
        } else if (keccak256(bytes(action)) == keccak256(bytes("approve"))) {
            if (amount == 0) revert("AMOUNT must be set for approve action");
            token.approve(stakingAddr, amount);
            console.log("Approved", amount, "for staking contract");
        } else if (keccak256(bytes(action)) == keccak256(bytes("stake"))) {
            if (amount == 0) revert("AMOUNT must be set for stake action");
            staking.stake(amount);
            console.log("Staked", amount);
        } else if (keccak256(bytes(action)) == keccak256(bytes("claim"))) {
            staking.claimRewards();
            console.log("Claimed rewards for", msg.sender);
        } else if (keccak256(bytes(action)) == keccak256(bytes("unstake"))) {
            if (amount == 0) revert("AMOUNT must be set for unstake action");
            staking.unstake(amount);
            console.log("Unstaked", amount);
        } else if (keccak256(bytes(action)) == keccak256(bytes("balance"))) {
            address addr = target == address(0) ? msg.sender : target;
            console.log("Token balance:", token.balanceOf(addr));
            console.log("Staked amount:", staking.getStaked(addr));
        } else {
            revert("Unknown ACTION, supported: mint|approve|stake|claim|unstake|balance");
        }

        vm.stopBroadcast();
    }
}
