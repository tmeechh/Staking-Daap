// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {MyToken} from "./MyToken.sol";

/*//////////////////////////////////////////////////////////////
                              ERRORS
//////////////////////////////////////////////////////////////*/
error Staking__ZeroAmount();
error Staking__InsufficientBalance();
error Staking__RewardTransferFailed();

/*//////////////////////////////////////////////////////////////
                               CONTRACT
//////////////////////////////////////////////////////////////*/

/// @title Token Staking Contract
/// @author Tmeech
/// @notice Users stake MTK tokens and earn rewards over time.
/// @dev Simple, gas-efficient staking model for portfolio-level DApps.
contract Staking is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                          TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/

    struct StakeInfo {
        uint256 staked;
        uint256 rewards;
        uint256 lastUpdate;
    }

    /*//////////////////////////////////////////////////////////////
                           STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;
    uint256 public immutable rewardRate; // tokens per second
    uint256 public totalStaked;

    mapping(address => StakeInfo) private s_stakes;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 reward);

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier updateRewards(address user) {
        StakeInfo storage stake = s_stakes[user];

        if (stake.staked > 0) {
            uint256 timeDiff = block.timestamp - stake.lastUpdate;
            uint256 newRewards = timeDiff * stake.staked * rewardRate;
            stake.rewards += newRewards;
        }

        stake.lastUpdate = block.timestamp;
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the staking contract with token + reward rate.
    /// @param _token The staking token (MTK).
    /// @param _rewardRate Reward tokens earned per second per staked token.
    constructor(address _token, uint256 _rewardRate) {
        stakingToken = IERC20(_token);
        rewardRate = _rewardRate;
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @notice Stake MTK tokens.
    /// @param amount The number of tokens to stake.
    function stake(uint256 amount) external nonReentrant updateRewards(msg.sender) {
        if (amount == 0) revert Staking__ZeroAmount();

        // safeTransferFrom will revert if transfer fails and supports
        // non-standard ERC20 implementations.
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        s_stakes[msg.sender].staked += amount;
        totalStaked += amount;

        emit Staked(msg.sender, amount);
    }

    /// @notice Unstake MTK tokens.
    /// @param amount The number of tokens to unstake.
    function unstake(uint256 amount) external nonReentrant updateRewards(msg.sender) {
        if (amount == 0) revert Staking__ZeroAmount();
        if (s_stakes[msg.sender].staked < amount) {
            revert Staking__InsufficientBalance();
        }

        s_stakes[msg.sender].staked -= amount;
        totalStaked -= amount;

        // Use safeTransfer for broader ERC20 compatibility
        stakingToken.safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    /// @notice Claim accumulated staking rewards.
    function claimRewards() external nonReentrant updateRewards(msg.sender) {
        uint256 reward = s_stakes[msg.sender].rewards;
        if (reward == 0) revert Staking__RewardTransferFailed();

        s_stakes[msg.sender].rewards = 0;

        // SafeERC20 will revert on failure
        stakingToken.safeTransfer(msg.sender, reward);

        emit RewardsClaimed(msg.sender, reward);
    }

    /*//////////////////////////////////////////////////////////////
                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice View how many tokens a user has staked.
    function getStaked(address user) external view returns (uint256) {
        return s_stakes[user].staked;
    }

    /// @notice View pending rewards for a user.
    function getPendingRewards(address user) external view returns (uint256) {
        StakeInfo memory stake = s_stakes[user];
        uint256 timeDiff = block.timestamp - stake.lastUpdate;

        return stake.rewards + (timeDiff * stake.staked * rewardRate);
    }
}
