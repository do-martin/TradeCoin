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
import "contracts/DebtContract.sol";

contract TradeRouteToken is ERC20, ERC20Pausable, Ownable, ERC20Permit {
    address initOwner;
    uint256 public maxTokens = 1000000000000; // 10 Billiarden
    uint8 internal EXCHANGERATE = 97;
    MiningContract private miningContract;
    DebtContract private debtContract;
    bool miningInProgress = false;

    constructor(address initialOwner)
        ERC20("Trade Route Token", "TRT")
        Ownable(initialOwner)
        ERC20Permit("Trade Route Token")
    {
        initOwner = initialOwner;
        debtContract = new DebtContract();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function myBalance() external view returns (uint256) {
        return balanceOf(msg.sender);
    }

    // function _update(
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }

    // functions
    function mintTokens(
        address to,
        uint256 amount,
        uint256 newMaxAmount
    ) private {
        require(maxTokens >= newMaxAmount, "Not enough tokens available.");
        _mint(to, amount);
    }

    function calculateExchangeRateInTokens(uint256 amount)
        private
        view
        returns (uint256)
    {
        return Math.ceilDiv((amount * EXCHANGERATE), 100); //100 Weis -> 97 Token
    }

    function calculateExchangeRateInEther(uint256 amount)
        private
        view
        returns (uint256)
    {
        return Math.ceilDiv((amount * 100), EXCHANGERATE); // 97 Token -> 100 Weis
    }

    function buyTokens() external payable {
        uint256 amount = calculateExchangeRateInTokens(msg.value);
        uint256 newTotalSupply = totalSupply() + amount;
        require(maxTokens >= newTotalSupply, "Not enough tokens available.");
        mintTokens(_msgSender(), amount, newTotalSupply);
    }

    function buyTokensFor(address to) external payable {
        // require(amount <= msg.value, "You must send more Wei.");
        uint256 amount = calculateExchangeRateInTokens(msg.value);
        uint256 newTotalSupply = totalSupply() + amount;
        require(maxTokens >= newTotalSupply, "Not enough tokens available.");
        mintTokens(to, amount, newTotalSupply);
    }

    function withdrawTokensGetEther(address payable recipient, uint256 amount)
        external
    {
        require(balanceOf(_msgSender()) >= amount, "Your credit is too low.");
        amount = calculateExchangeRateInEther(amount);
        require(address(this).balance >= amount, "Insufficient balance");

        recipient.transfer(amount);
    }

    //  function sendEtherCheck(address payable inputAddress, uint256 amount)
    //     public
    //     returns (bool)
    // {
    //     require(amount > 0, "Amount should be greater than 0.");
    //     if (inputAddress == msg.sender) {
    //         revert("Destination address shouldn't be equal to sender address.");
    //     } else {
    //         return inputAddress.send(amount);
    //     }
    // }

    function mining() private onlyOwner {
        // should be private onlyOwner
        require(totalSupply() > 0, "Total supply must be greater than 0.");
        require(!miningInProgress, "Mining is already in progress.");
        miningContract = new MiningContract(
            EXCHANGERATE,
            maxTokens,
            symbol(),
            name(),
            totalSupply()
        );
        miningInProgress = true;
    }

    function tryToGetBlock(string memory input)
        external
        returns (bool, bytes32)
    {
        (bool miningResult, bytes32 hashedValue) = (
            miningContract.mineTokens(_msgSender(), input)
        );
        if (miningResult) {
            uint256 rewards = miningContract.getRewards();
            mintTokens(_msgSender(), rewards, rewards + totalSupply());
            miningInProgress = false;
        }
        return (miningResult, hashedValue);
    }

    function getMiningRewards() public view returns (uint256) {
        return miningContract.getRewards();
    }

    function getMiningTask() public view returns (string memory) {
        return miningContract.getMiningTask();
    }

    // function testMining(string memory miningTask, string memory input) public pure returns(bool){
    //     string memory mergedTask = string.concat(miningTask, input);

    //     bytes32 mergedTaskHash = keccak256(abi.encode(mergedTask));

    //     for (uint8 i = 0; i <= 0; i++) {
    //         bytes1 prefixHash = mergedTaskHash[i];      // gets i-th byte of mergedTaskHash -> Hexadezimal -> 1/2 Byte
    //         if (prefixHash == 0x1A) {
    //             return true;
    //         }
    //     }
    //     return false;
    // }

    // function createNewDebtListByCreditor(address creditor, address debtor, uint256 amount, uint256 interest) external{

    // }

    function createNewDebtList(
        address creditor,
        uint256 amount,
        uint256 interest
    ) external {
        uint256 addToDebtFund = Math.ceilDiv((amount * interest), 100);
        if (addToDebtFund < 1) {
            addToDebtFund = 1;
        }
        // check if balance of creditor is high enough
        require(
            (balanceOf(creditor) + addToDebtFund) >= amount,
            "Creditor's balance is not high enough."
        );
        require(creditor != msg.sender, "You can't be your own creditor.");
        // create new debt list
        if (
            debtContract.createDebtList(
                msg.sender,
                creditor,
                amount,
                interest
                // addToDebtFund
            )
        ) {
            // send token from creditor to debtor
            // _update(creditor, msg.sender, amount);
        }
    }

    function validateDebtList(
        address debtor,
        uint256 amount,
        uint256 interest
    ) external {
        uint256 addToDebtFund = Math.ceilDiv((amount * interest), 100);
        if (addToDebtFund < 1) {
            addToDebtFund = 1;
        }
        require(
            (balanceOf(msg.sender) + addToDebtFund) >= amount,
            "Creditor's balance is not high enough."
        );
        require(
            debtContract.validateDebtList(
                debtor,
                msg.sender,
                amount,
                interest,
                addToDebtFund
            ),
            "Validation of debt list failed."
        );
        // send token from creditor to debtor
        _update(msg.sender, debtor, amount);
    }

    function repayDebt(address creditor, uint256 amount) external payable {
        require(
            (balanceOf(msg.sender) >= amount),
            "Debtor's balance is not high enough."
        );
        uint256 amountOrRestOfRepay = debtContract.repayDebt(
            msg.sender,
            creditor,
            amount
        );
        if (!debtContract.getCreditorAlreadyGetFromDebtFundBool(msg.sender)) {
            if (amountOrRestOfRepay == amount) {
                _update(msg.sender, creditor, amount);
            } else {
                _update(msg.sender, creditor, (amount - amountOrRestOfRepay));
            }
        } else {
            if (amountOrRestOfRepay == amount) {
                _update(msg.sender, initOwner, amount);
            } else {
                _update(msg.sender, initOwner, (amount - amountOrRestOfRepay));
            }
        }
    }

    function tryToGetDebtBlock(string memory input) external returns(bool, bytes32){
        (bool result, bytes32 message) = debtContract.tryToGetBlock(
            msg.sender,
            input
        );
        if (result) {
            (address creditor, uint256 amount) = debtContract
                .setCreditorAlreadyGetFromDebtFund();
            _update(initOwner, creditor, amount);
        }
        return (result, message);
    }

//  takePieceOfDebtFund(
//         address debtor,
//         uint256 currentDebt,
//         uint8 exchangeRate,
//         uint8 maxTokens,
//         string memory symbol,
//         string memory name,
//         uint256 totalSupply
//     function getMyTokensBack(address debtor, )

    // function getCurrentDebtAmount() public view returns (uint256) {
    //     return debtContract.getCurrentDebtAmount();
    // }

    // function getDebtFund() public view returns (uint256) {
    //     return debtContract.getDebtFund();
    // }

    // function getMyAmountOfDebt() public view returns (address, uint256) {
    //     return debtContract.getDebtCreditorAndAmount(msg.sender);
    // }

    // function getHashCode(string memory input) public pure returns (bytes32) {
    //     return keccak256(abi.encodePacked(input));
    // }

    // function test() public view returns (uint256) {
    //     return msg.sender.balance;
    // }
}
