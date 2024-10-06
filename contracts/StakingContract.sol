// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "contracts/MiningContract.sol";


contract StakingContract {
    uint256 public totalStakes;
    uint256 public totalRewards;
    mapping(address => uint256) public stakers;
    mapping(address => uint256) public rewards;
    address[] public stakersAddresses;

    // Events
    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event Rewarded(address indexed staker, uint256 amount);

    constructor() {}

    // functions for staking the tokens
    function stake(address staker, uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        if (stakers[staker] < 1) {
            stakersAddresses.push(staker);
        }
        stakers[staker] += amount;
        totalStakes += amount;
        emit Staked(staker, amount);
    }

    // functions for unstaking the tokens
    function unstake(address staker, uint256 amount) public returns (bool) {
        require(
            totalStakes >= amount,
            "There are not enough coins in your staking pool."
        );
        require(stakers[staker] >= amount, "Amount must be greater than 0.");
        stakers[staker] -= amount;
        totalStakes -= amount;
        emit Unstaked(staker, amount);
        return true;
    }

    // distribute rewards
    // function distributeRewards(uint256 amount) public {
    //     require(totalStakes > 0, "No stakes found");

    //     uint256 rewardPerToken = amount / totalStakes;
    //     // for (uint256 i = 0; i < numberOfStakers; i++) {
    //     //     uint256 reward = stakers[i] * rewardPerToken;
    //     // }

    //     // Aktualisierung der Belohnungen für jeden Staker
    //     // for (uint256 i = 0; i < stakers.length; i++) {
    //     //     address staker = stakers[i];
    //     //     uint256 reward = stakes[staker] * rewardPerToken;
    //     //     rewards[staker] += reward;
    //     //     totalRewards += reward;
    //     //     emit Rewarded(staker, reward);
    //     // }
    // }
}
