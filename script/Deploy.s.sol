// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";
import {Staking} from "../src/Staking.sol";
import {HelperConfig} from "./HelperConfig.sol";

contract DeployScript is Script {
    function addressToHexString(
        address _addr
    ) internal pure returns (string memory) {
        bytes20 v = bytes20(_addr);
        bytes memory ret = new bytes(42);
        ret[0] = "0";
        ret[1] = "x";
        bytes memory hexSymbols = "0123456789abcdef";
        for (uint i = 0; i < 20; i++) {
            ret[2 + i * 2] = hexSymbols[uint8(uint8(v[i]) >> 4)];
            ret[3 + i * 2] = hexSymbols[uint8(uint8(v[i]) & 0x0f)];
        }
        return string(ret);
    }
    function run() external {
        // Start broadcasting.
        // - If you deployed using `--keystore <name>` or `--private-key <key>` via the CLI
        //   you can simply call `vm.startBroadcast()` and Foundry will sign with the
        //   provided key. If you prefer to pass a key in env use PRIVATE_KEY.
        // Prefer env lookups that default to 0 instead of reverting when not set
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0));
        if (deployerPrivateKey != 0) {
            // explicit private key path: keep this option for non-interactive CI
            vm.startBroadcast(deployerPrivateKey);
        } else {
            // use CLI signer (for example: `forge script ... --keystore raffletest --broadcast`)
            vm.startBroadcast();
        }

        // Deploy token
        MyToken token = new MyToken();

        HelperConfig helperConfig = new HelperConfig();

        console.log("Deploying with chain id:", block.chainid);
        // Allow env overrides for reward rate + initial mint (helpful for fast tuning on Sepolia)
        uint256 rewardRate = helperConfig.REWARD_RATE();
        uint256 initialMint = helperConfig.INITIAL_MINT();

        uint256 overrideReward = vm.envOr("REWARD_RATE_OVERRIDE", uint256(0));
        uint256 overrideMint = vm.envOr("INITIAL_MINT_OVERRIDE", uint256(0));
        if (overrideReward != 0) {
            console.log(
                "Override reward rate provided via REWARD_RATE_OVERRIDE"
            );
            rewardRate = overrideReward;
        }
        if (overrideMint != 0) {
            console.log(
                "Override initial mint provided via INITIAL_MINT_OVERRIDE"
            );
            initialMint = overrideMint;
        }

        console.log("Using reward rate:", rewardRate);
        console.log("Initial mint:", initialMint);

        // Deploy staking contract with reward rate (call the generated getter on the instance)
        Staking staking = new Staking(address(token), rewardRate);

        // Mint initial rewards to staking
        token.mint(address(staking), initialMint);

        // Log addresses for reference
        console.log("Token deployed at:", address(token));
        console.log("Staking deployed at:", address(staking));

        // Write a small JSON file under /deployments so the frontend or other
        // tooling can easily pick up the latest addresses for this chain.
        // The file will be: deployments/<chainName>.json
        string memory chainName = "unknown";
        if (block.chainid == 31337) {
            chainName = "anvil";
        } else if (block.chainid == 11155111) {
            chainName = "sepolia";
        } else {
            chainName = string.concat("chain-", vm.toString(block.chainid));
        }

        // helper to format address as hex-string (function is contract-scoped above)

        string memory json = string.concat(
            '{"network":"',
            chainName,
            '",',
            '"token":"',
            addressToHexString(address(token)),
            '",',
            '"staking":"',
            addressToHexString(address(staking)),
            '",',
            '"deployer":"',
            addressToHexString(msg.sender),
            '"}'
        );

        // Optionally write a small deployments file with addresses. Writing to
        // disk is not always allowed when running remotely (some runners /
        // environments disallow file writes for security). We only write when
        // ALLOW_DEPLOY_FILE_WRITE is set to a truthy value in the env.
        // uint256 allowWrite = vm.envOr("ALLOW_DEPLOY_FILE_WRITE", uint256(0));
        // if (allowWrite != 0) {
        //     string memory path = string.concat(
        //         "deployments/",
        //         chainName,
        //         ".json"
        //     );
        //     vm.writeFile(path, json);
        //     console.log("Wrote deployment info to:", path);
        // } else {
        //     console.log(
        //         "Skipped writing deployments file (set ALLOW_DEPLOY_FILE_WRITE=1 to enable)"
        //     );
        // }

        // Helpful verification note:
        // - If you want to automatically verify sources on Etherscan, set ETHERSCAN_API_KEY
        //   in your environment and run the same forge command with `--verify`.
        // Example:
        //   export SEPOLIA_RPC_URL=...; export ETHERSCAN_API_KEY=...
        //   forge script script/Deploy.s.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --keystore raffletest --broadcast --verify
        console.log(
            "NOTE: to auto-verify on Etherscan use --verify and ensure ETHERSCAN_API_KEY is set in your env"
        );

        vm.stopBroadcast();
    }
}
