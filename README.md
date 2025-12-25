## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

# Staking-dapp — MTK staking demo (Foundry)

Minimal, test-first staking project built with Foundry. This repo contains a small ERC20 token (MyToken) and a gas-conscious staking contract (Staking) plus deploy & interaction scripts geared for both local development (Anvil) and Sepolia testnet.

Why this repo
- Small, readable smart contracts designed for learning and frontend integration.
- Scripts and tooling favor safety (keystore-based signing), verification-ready deployment, and explicit steps for interactions.

Prerequisites
- Foundry installed (forge, cast, anvil). Install docs: https://book.getfoundry.sh/
- An Alchemy/Infura Sepolia RPC URL and an Etherscan API key for verification.
- A foundry keystore (recommended) or a private key for CI only — DO NOT commit secrets.

Environment variables
Create a local .env (keep this out of source control):

```env
SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/<YOUR_KEY>"
ETHERSCAN_API_KEY=<YOUR_ETHERSCAN_KEY>
```

Build & test

```bash
forge build
forge test --match-evm test
forge fmt
```

Deploy to Sepolia (recommended using your local foundry keystore)

1) Make sure the keystore account has Sepolia ETH (faucet).
2) Run deploy (foundry will prompt for the keystore passphrase):

```bash
source .env
forge script script/Deploy.s.sol:DeployScript \
	--rpc-url "$SEPOLIA_RPC_URL" \
	--keystore ~/.foundry/keystores/<your-keystore-file> \
	--broadcast \
	--verify
```

- Output includes deployed addresses and transaction hashes. Foundry's `--verify` will ask Etherscan to verify the source automatically using `ETHERSCAN_API_KEY`.

Where to find deployed addresses
- Foundry prints addresses to stdout after deploy.
- Also check `broadcast/Deploy.s.sol/<chain>/run-*.json`.

Interaction scripts
- Use `script/InteractSepolia.s.sol` for Sepolia — it is pre-filled with the deployed addresses (safe toggles to enable a single action at a time).
- Generic `script/Interact.s.sol` is available and requires you to set `TOKEN_ADDR`, `STAKING_ADDR`, and `ACTION` values inside the file before running.

Example sequence (owner & staker flow)
1. Mint tokens (owner):
```
cast send <TOKEN_ADDR> "mint(address,uint256)" <RECIPIENT> <AMOUNT_WEI> --rpc-url "$SEPOLIA_RPC_URL" --keystore ~/.foundry/keystores/<owner-keystore>
```
2. From the staker's address: approve then stake
```
cast send <TOKEN_ADDR> "approve(address,uint256)" <STAKING_ADDR> <AMOUNT_WEI> --rpc-url "$SEPOLIA_RPC_URL" --keystore ~/.foundry/keystores/<staker-keystore>
cast send <STAKING_ADDR> "stake(uint256)" <AMOUNT_WEI> --rpc-url "$SEPOLIA_RPC_URL" --keystore ~/.foundry/keystores/<staker-keystore>
```
3. Claim and Unstake
```
cast send <STAKING_ADDR> "claimRewards()" --rpc-url "$SEPOLIA_RPC_URL" --keystore ~/.foundry/keystores/<staker-keystore>
cast send <STAKING_ADDR> "unstake(uint256)" <AMOUNT_WEI> --rpc-url "$SEPOLIA_RPC_URL" --keystore ~/.foundry/keystores/<staker-keystore>
```

Safety & best-practices (recommended, non-blocking)
- NEVER commit private keys or keystore passwords. Use keystore signing locally and CI secrets for pipelines.
- Consider using OpenZeppelin's SafeERC20 wrappers (safeTransfer/safeTransferFrom) for broader token compatibility.
- Add ReentrancyGuard to externally-facing state-change flows (claim/unstake) for production-level safety.
- Add more granular unit & integration tests covering edge cases (staking 0, over-unstake, concurrency). Invariants tests are already present which is good.

File map (high level)
- src/
	- MyToken.sol — ERC20 (owner-mint) with NatSpec & events
	- Staking.sol — staking contract with events, errors, updateRewards modifier
- script/
	- Deploy.s.sol — network aware deploy script (support for optional deployment file write and Etherscan verification)
	- Interact.s.sol — generic interact script (edit placeholders before use)
	- InteractSepolia.s.sol — Sepolia-ready interact script with safe toggles and explicit amounts
	- HelperConfig.sol — per-network defaults for reward and initial mint
- broadcast/ — foundry run artifacts and logs
- test/ — unit and invariant tests

Next recommended actions
1. Small security sweep: adopt SafeERC20, ReentrancyGuard, and review reward accounting for high volumes.
2. Add a CI job to run unit + invariant tests and optionally a forked Sepolia smoke-deploy.
3. Produce frontend artifacts: deployment JSON and typed contract bindings (TypeChain or viem) for a polished FE integration.

Exporting ABIs & deployment info for the frontend
-------------------------------------------------
After you deploy to Sepolia (or run a local deploy) you'll want the frontend to have:
- Contract ABIs (MyToken, Staking)
- Deployed addresses (e.g., deployments/sepolia.json).


## 📜 License

This project is licensed under the MIT License.

🔥 Built with love, Solidity, and caffeine.