// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HelperConfig {
    /// @notice Network-specific configuration used by the deployment script.
    /// Keeping these values in a small helper keeps the deploy script concise
    /// while still giving sane defaults for local vs public testnets.
    struct NetworkConfig {
        uint256 rewardRate; // tokens per second (scaled to token decimals)
        uint256 initialMint; // initial amount to seed the staking contract
    }

    NetworkConfig public activeConfig;

    /// @notice Supported chain ids
    uint256 private constant CHAIN_ANVIL = 31337;
    uint256 private constant CHAIN_SEPOLIA = 11155111;

    /// @notice Set network-aware configuration at deployment time.
    /// The deploy script relies on this helper for sane defaults; you can
    /// still override values at deployment time via environment variables
    /// (see `Deploy.s.sol`) if you need non-default behavior.
    constructor() {
        if (block.chainid == CHAIN_ANVIL) {
            // extremely fast local testing: generous mint and tiny reward rate
            activeConfig = NetworkConfig({rewardRate: 1, initialMint: 1_000_000e18});
        } else if (block.chainid == CHAIN_SEPOLIA) {
            // example Sepolia settings (scaled-down rewards, real-looking supply)
            // - rewardRate uses token (18 decimals) scaling. Choose conservatively.
            activeConfig = NetworkConfig({rewardRate: 1e15, initialMint: 100_000e18});
        } else {
            // safe defaults for other networks
            activeConfig = NetworkConfig({rewardRate: 1, initialMint: 10_000e18});
        }
    }

    /// @notice Convenience getters to mirror previous API and make scripts
    /// compatible with older versions.
    function REWARD_RATE() external view returns (uint256) {
        return activeConfig.rewardRate;
    }

    function INITIAL_MINT() external view returns (uint256) {
        return activeConfig.initialMint;
    }
}
