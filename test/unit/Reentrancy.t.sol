// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../..//src/MyToken.sol";
import {Staking} from "../..//src/Staking.sol";

/// @notice A malicious token that tries to re-enter the staking contract
/// during transfers (used only for unit testing the reentrancy guard).
contract AttackToken is MyToken {
    address public target;
    bool public reenter;

    constructor() MyToken() {}

    function setTarget(address _target) external {
        target = _target;
    }

    function setReenter(bool _reenter) external {
        reenter = _reenter;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        bool ok = super.transfer(to, amount);
        if (reenter && target != address(0)) {
            // try to re-enter claimRewards on the staking contract
            Staking(target).claimRewards();
        }
        return ok;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        bool ok = super.transferFrom(from, to, amount);
        if (reenter && target != address(0)) {
            Staking(target).claimRewards();
        }
        return ok;
    }
}

contract ReentrancyTest is Test {
    AttackToken token;
    Staking staking;

    function setUp() public {
        token = new AttackToken();
        // reward rate: use small value so rewards remain reasonable in tests
        staking = new Staking(address(token), 1);

        // mint tokens to test contract and give allowance to staking
        token.mint(address(this), 100 * 1e18);
        token.approve(address(staking), type(uint256).max);

        // stake 1 token
        staking.stake(1e18);

        // ensure staking contract has tokens to pay rewards
        token.mint(address(staking), 100 * 1e18);
    }

    function testClaimRevertsWhenTokenReenters() public {
        // advance time so rewards are non-zero
        vm.warp(block.timestamp + 10);

        // configure token to attempt reentry when transfers occur
        token.setTarget(address(staking));
        token.setReenter(true);

        // claimRewards should revert due to nonReentrant
        vm.expectRevert();
        staking.claimRewards();
    }

    function testClaimSucceedsWhenNoReentry() public {
        token.setReenter(false);
        vm.warp(block.timestamp + 10);

        // should not revert
        staking.claimRewards();

        // ensure rewards are zero afterward
        uint256 pending = staking.getPendingRewards(address(this));
        assertEq(pending, 0);
    }
}
