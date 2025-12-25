// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../..//src/MyToken.sol";
import {Staking} from "../..//src/Staking.sol";

contract ForkSepolia is Test {
    function testForkedSepoliaDeployAndStake() public {
        string memory url = vm.envString("SEPOLIA_RPC_URL");
        if (bytes(url).length == 0) return; // skip if no fork URL provided

        uint256 forkId = vm.createFork(url);
        vm.selectFork(forkId);

        // Deploy contracts on the fork (this only affects the fork, not mainnet)
        MyToken token = new MyToken();
        Staking staking = new Staking(address(token), 1e15);

        // Mint + approve + stake flow
        token.mint(address(this), 10 * 1e18);
        token.approve(address(staking), 10 * 1e18);
        staking.stake(1 * 1e18);

        assertEq(staking.getStaked(address(this)), 1 * 1e18);
    }
}
