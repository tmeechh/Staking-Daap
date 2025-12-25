// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/
import {Test} from "forge-std/Test.sol";
import {MyToken} from "../../src/MyToken.sol";

/*//////////////////////////////////////////////////////////////
                            TEST CONTRACT
//////////////////////////////////////////////////////////////*/

/// @title Token Tests for MyToken ERC20 Contract
/// @author You
contract TokenTest is Test {
    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/
    uint256 public constant MINT_AMOUNT = 1e18;
    MyToken token;
    address owner = address(1);
    address user = address(2);

    /*//////////////////////////////////////////////////////////////
                              SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        vm.prank(owner);
        token = new MyToken();
    }

    /*//////////////////////////////////////////////////////////////
                               TESTS
    //////////////////////////////////////////////////////////////*/

    function test_OwnerCanMint() public {
        // Arrange
        vm.prank(owner);
        uint256 mintAmount = MINT_AMOUNT;

        // Act
        token.mint(user, mintAmount);

        // Assert
        assertEq(token.balanceOf(user), mintAmount);
    }

    function test_NonOwnerCannotMint() public {
        // Arrange
        vm.prank(user);
        uint256 mintAmount = MINT_AMOUNT;

        // Act + Assert
        vm.expectRevert();
        token.mint(user, mintAmount);
    }
}
