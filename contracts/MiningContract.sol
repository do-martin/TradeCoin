// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../@trt-utils/TRTStrings.sol";
import "contracts/MiningContract.sol";
import "contracts/StakingContract.sol";

contract MiningContract {
    // token informations
    uint256 public maxTokens;
    uint256 public totalSupply;
    string public symbol;
    string public name;
    uint8 public exchangeRate;

    // mining informations
    uint256 public blockNumber;
    bytes32 public blockHash;
    uint8 internal rewardRate = 1;

    string public miningTask;
    uint256 public miningRewards;

    uint8 PREFIXLENGTH = 0;
    bytes1 PREFIXHASHVALUE = 0x90;

    event MiningRunning(
        uint256 indexed minedBlockNumber,
        bytes32 indexed blockHash,
        string indexed miningTask
    );
    
    event Mined(
        address indexed miner,
        uint256 indexed minedBlockNumber,
        uint256 indexed rewards
    );

    // event TestNum(uint256 indexed blocke);
    // event TestStr(string indexed blocke);
    // event TestBytes32(bytes32 indexed input);

    constructor(
        uint8 exchRate,
        uint256 maxTok,
        string memory symb,
        string memory nameGet,
        uint256 totalSup
    ) {
        blockNumber = block.number;
        blockHash = blockhash(blockNumber);
        exchangeRate = exchRate;
        maxTokens = maxTok;
        symbol = symb; 
        name = nameGet; 
        totalSupply = totalSup;
        miningTask = calculateMiningTask();

        miningRewards = calculateMiningRewards(totalSupply);
        emit MiningRunning(blockNumber, blockHash, miningTask);
    }

    function calculateMiningRewards(uint256 totalSup)view 
        private
        returns (uint256)
    {
        uint256 rewards = Math.ceilDiv(totalSup, exchangeRate);
        return rewards;
    }

    function calculateMiningTask()
        private
        view
        returns (string memory calculatedTask)
    {
        uint256 newMaxTokens = totalSupply + miningRewards;
        require(maxTokens >= newMaxTokens, "Not enough tokens available.");

        // addition of maxTokens, EXCHANGERATE, totalSupply, symbol, name and your 'input'
        string memory stringMaxTokens = Strings.toString(maxTokens);
        string memory stringTotalSupply = Strings.toString(totalSupply);
        string memory stringName = name;
        string memory stringBlockHash = string(abi.encodePacked(blockHash));
        string memory calcTask = string.concat(
            stringName,
            stringMaxTokens,
            stringTotalSupply,
            stringBlockHash
        );
        return calcTask;
    }

    function mineTokens(address miner, string memory input)
        public
        returns (bool, bytes32)
    {
        string memory mergedTask = string.concat(miningTask, input);

        bytes32 mergedTaskHash = keccak256(abi.encode(mergedTask));
        
        for (uint8 i = 0; i <= 256/8; i++) {
            // gets i-th byte of mergedTaskHash -> Hexadezimal -> 1/2 Byte
            bytes1 prefixHash = mergedTaskHash[i];      
            if (prefixHash == PREFIXHASHVALUE) {
                emit Mined(miner, blockNumber, miningRewards);
                return (true, mergedTaskHash);
            }
        }
        return (false, mergedTaskHash);
    }

    function getRewards() public view returns (uint256) {
        return miningRewards;
    }

    function getMiningTask() public view returns (string memory){
        return miningTask;
    }
}
