// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "contracts/models/ModelLibrary.sol";
import "contracts/MiningContract.sol";

contract DebtContract {
    using ModelLibrary for ModelLibrary.Creditor;

    mapping(address => ModelLibrary.Creditor) public debtList;
    uint256 currentDebtAmount;
    uint256 allTimePayback;
    uint256 public debtFund;

    bool takingPieceOfDebtFundInProgress = false;

    address currentMiningAddress;
    uint256 currentMiningAmount;
    MiningContract currentMiningContract;

    // mapping(address => uint256) public debtFundProgressMappingDebtAmount;
    // mapping(address => MiningContract) public debtFundProgressMappingMining;

    event newDebt(uint256 indexed amount);
    event repayDebtToZero(uint256 indexed amount);
    event takePieceOfDebtFundCall(uint256 indexed amount);

    function createDebtList(
        address debtor,
        address creditor,
        uint256 amount,
        uint256 fees
    )
        public
        returns (
            // uint256 addToDebtFund
            bool
        )
    {
        // Ensure the debtor doesn't already have debt
        require(
            debtList[debtor].getDebtAmount() == 0,
            "Debtor already have debt."
        );
        require(amount > 0, "Amount of debt have to be greater than 0.");
        require(fees > 0, "Interest has to be greater than 0.");

        // Create a new creditor and set them as the creditor for the debtor
        debtList[debtor] = ModelLibrary.createCreditor(
            creditor,
            amount,
            fees,
            block.timestamp,
            false,
            false
        );
        // currentDebtAmount = currentDebtAmount + amount;
        // debtFund = debtFund + addToDebtFund;
        // emit newDebt(amount);
        return true;
    }

    function validateDebtList(
        address debtor,
        address creditor,
        uint256 amount,
        uint256 fees,
        uint256 addToDebtFund
    ) external returns (bool) {
        require(debtList[debtor].getDebtAmount() != 0, "Debtor doesn't exist.");
        require(amount > 0, "Amount of debt have to be greater than 0.");
        require(fees > 0, "Interest has to be greater than 0.");
        ModelLibrary.Creditor storage debtContract = debtList[debtor];
        require(
            (debtContract.getCreditorAddress() == creditor &&
                debtContract.getDebtAmount() == amount &&
                debtContract.getInterest() == fees),
            "Validation failed."
        );
        debtList[debtor].setTimeOfDebt(block.timestamp);
        debtList[debtor].setValidation();

        currentDebtAmount = currentDebtAmount + amount;
        debtFund = debtFund + addToDebtFund;
        emit newDebt(amount);
        return true;
    }

    /* The function is intended for debtors to repay their debt to their creditors. 
    After the repayment, it checks if the creditor also has debt. If so, the money 
    is directly forwarded to their creditors, leading to recursion, which can result 
    in high gas fees.*/

    function repayDebt(
        address debtor,
        address creditor,
        uint256 amount
    ) external payable returns (uint256 restDebt) {
        // Ensure the debtor-creditor pair is available
        require(
            debtList[debtor].getCreditorAddress() == creditor,
            "Debtor-Credit-Pair is unvailable."
        );
        //Calculate amount for debt fund
        uint256 amountDebtFund = calculateDebtFund(amount);
        amount -= amountDebtFund;
        debtFund += amountDebtFund;
        // Calculate the interest
        uint256 debtAmount = debtList[debtor].getDebtAmount();
        uint256 debtInterest = calculateInterestUntil(
            debtAmount,
            debtList[debtor].getTimeOfDebt(),
            block.timestamp,
            debtList[debtor].getInterest()
        );
        currentDebtAmount += debtInterest;
        // Update amount of debt to sum of debt plus interest
        debtList[debtor].setDebtAmount(debtAmount + debtInterest);
        uint256 debtAmountPlusInterest = debtList[debtor].getDebtAmount();
        // Update timestamp to Zero
        debtList[debtor].setTimeOfDebt(block.timestamp);
        // Check if the debt plus the interest are greater than or equal to the repayment amount
        bool debtHigherThanInput = (debtAmountPlusInterest) > amount;
        uint256 restAfterDebtRepaying = 0;
        if (debtHigherThanInput) {
            // If the debt plus the interest are greater than or equal to the repayment amount, subtract the repayment amount from the debt
            debtList[debtor].setDebtAmount(debtAmountPlusInterest - amount);
            require(
                currentDebtAmount - amount >= 0,
                "End current debt amount should be greater than 0."
            );
            currentDebtAmount = currentDebtAmount - amount;
            allTimePayback = allTimePayback + amount;
            return amount;
        } else {
            // If the debt is less than the repayment amount, calculate the remaining amount after repaying the debt
            restAfterDebtRepaying = amount - debtAmountPlusInterest;
            debtList[debtor].setDebtAmount(0);
            uint256 repayingDebtAmount = amount - restAfterDebtRepaying;
            require(
                currentDebtAmount - repayingDebtAmount >= 0,
                "End current debt amount should be greater than 0."
            );
            currentDebtAmount = currentDebtAmount - repayingDebtAmount;
            allTimePayback = allTimePayback + repayingDebtAmount;
            // Emit an event to signal that the debt have been fully repaid
            emit repayDebtToZero(repayingDebtAmount);
            return restAfterDebtRepaying;
        }
        // Check if the creditor's debt amount becomes zero after the repayment
        // if (debtList[creditor].getDebtAmount() == 0) {
        //     // If the creditor's debt amount becomes zero, return the remaining amount after repaying the debt
        //     // return restAfterDebtRepaying;
        // } else {
        //     // If the creditor still has remaining debt, repay them to the next creditor recursively
        //     address newCreditor = debtList[creditor].getCreditorAddress();
        //     repayDebt(creditor, newCreditor, restAfterDebtRepaying);
        // }
        // return restAfterDebtRepaying;
    }

    // function immediateRepayment(address debtor) public{
    //     require(debtFund >= debtList[]
    // }

    function getDebtCreditorAndAmount(address debtor)
        public
        view
        returns (address, uint256)
    {
        return (
            debtList[debtor].getCreditorAddress(),
            debtList[debtor].getDebtAmount()
        );
    }

    function calculateInterestUntil(
        uint256 principalAmount,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 interestRate
    ) private pure returns (uint256) {
        require(
            endTimestamp >= startTimestamp,
            "Start and end timestamps don't match"
        );

        uint256 differentStamp = (endTimestamp - startTimestamp) / 30; // different timestamp
        uint256 interest = ((principalAmount * interestRate) / 100); // amount * interst in %

        return (differentStamp * interest);

        // uint256 elapsedDays = (endTimestamp - startTimestamp) / 1 days;
        // uint256 annualInterest = (principalAmount * interestRate) / 100;
        // uint256 dailyInterest = annualInterest / 365; // daily interest

        // uint256 interest = elapsedDays * dailyInterest;
        // return interest;
    }

    function calculateDebtFund(uint256 paybackAmount)
        private
        pure
        returns (uint256)
    {
        uint16 feesPercentage = 1;
        uint256 absoluteFeesAmount = 0;

        absoluteFeesAmount = (paybackAmount / 100) * feesPercentage;
        if (absoluteFeesAmount == 0) {
            return 1;
        }
        return absoluteFeesAmount;
    }

    function getCurrentDebtAmount() public view returns (uint256) {
        return currentDebtAmount;
    }

    function getDebtFund() public view returns (uint256) {
        return debtFund;
    }

    function getCreditorAlreadyGetFromDebtFundBool(address debtor)
        public
        view
        returns (bool)
    {
        return debtList[debtor].getGetAlreadyFromdebtFund();
    }

    function setCreditorAlreadyGetFromDebtFund()
        public
        returns (address, uint256)
    {
        debtList[currentMiningAddress].setGetAlreadyFromDebtFund();

        debtFund -= currentMiningAmount;
        return (
            debtList[currentMiningAddress].getCreditorAddress(),
            currentMiningAmount
        );
    }

    function takePieceOfDebtFund(
        address debtor,
        uint256 currentDebt,
        // uint8 exchangeRate,
        // uint8 maxTokens,
        string memory symbol,
        string memory name,
        uint256 totalSupply
    ) public {
        require(
            takingPieceOfDebtFundInProgress == false,
            "Taking piece of debt fund is already in progess. Try again later."
        );
        takingPieceOfDebtFundInProgress = true;
        currentMiningAddress = debtor;
        currentMiningAmount = currentDebt;
        currentMiningContract = new MiningContract(
            5, //exchangeRate,
            debtFund, //maxTokens,
            symbol,
            name,
            totalSupply
        );
    }

    function tryToGetBlock(address miner, string memory input)
        public
        returns (bool, bytes32)
    {
        (bool success, bytes32 result) = currentMiningContract.mineTokens(
            miner,
            input
        );
        if (success) {
            takingPieceOfDebtFundInProgress = false;
        }
        return (success, result);
    }

    function getCreditorDataByDebtorAddress(address debtor)
        public
        view
        returns (ModelLibrary.Creditor memory)
    {
        return debtList[debtor];
    }

    function getCurrentMiningAddress() public view returns (address) {
        return currentMiningAddress;
    }

    function getCurrentMining() public view returns (MiningContract) {
        return currentMiningContract;
    }
}
