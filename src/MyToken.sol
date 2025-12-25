// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/*//////////////////////////////////////////////////////////////
                            CONTRACT
//////////////////////////////////////////////////////////////*/

/// @title MyToken (MTK) - ERC20 Token for Staking DApp
/// @author Tmeech
/// @notice This token is used for staking inside the staking contract.
/// @dev Mintable only by the deployer; ideal for testing & local deployments.
contract MyToken is ERC20 {
    /*//////////////////////////////////////////////////////////////
                               STATE
    //////////////////////////////////////////////////////////////*/

    address public immutable i_owner;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event TokensMinted(address indexed to, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                             FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys the token and sets the deployer as the owner.
    constructor() ERC20("MyToken", "MTK") {
        i_owner = msg.sender;
    }

    /// @notice Mints tokens for testing or distribution.
    /// @dev Only the owner (deployer) can mint. Kept simple for staking demos.
    /// @param to The address receiving the minted tokens.
    /// @param amount The number of tokens to mint.
    function mint(address to, uint256 amount) external {
        // Only the owner may mint tokens.
        require(msg.sender == i_owner, "NotAuthorized");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }
}
