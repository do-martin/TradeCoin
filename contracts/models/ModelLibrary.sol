// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library ModelLibrary {
    struct Creditor {
        address creditorAddress;
        uint256 debtAmount;
        uint256 interest; // in percent
        uint256 timeOfDebt;
        bool validate;
        bool alreadyGetFromDebtFund;
    }

    function createCreditor(
        address _creditorAddress,
        uint256 _debtAmount,
        uint256 _interest,
        uint256 _timeOfDebt,
        bool _validate,
        bool _alreadyGetFromDebtFund
    ) public pure returns (Creditor memory) {
        return
            Creditor(
                _creditorAddress,
                _debtAmount,
                _interest,
                _timeOfDebt,
                _validate,
                _alreadyGetFromDebtFund
            );
    }

    function getCreditorAddress(Creditor storage self)
        internal
        view
        returns (address)
    {
        return self.creditorAddress;
    }

    function setDebtAmount(Creditor storage self, uint256 _debtAmount)
        internal
    {
        self.debtAmount = _debtAmount;
    }

    function getDebtAmount(Creditor storage self)
        internal
        view
        returns (uint256)
    {
        return self.debtAmount;
    }

    function getInterest(Creditor storage self)
        internal
        view
        returns (uint256)
    {
        return self.interest;
    }

    function setTimeOfDebt(Creditor storage self, uint256 _timeOfDebt)
        internal
    {
        self.timeOfDebt = _timeOfDebt;
    }

    function getTimeOfDebt(Creditor storage self)
        internal
        view
        returns (uint256)
    {
        return self.timeOfDebt;
    }

    function setValidation(Creditor storage self) internal{
        self.validate = true;
    }

    function setGetAlreadyFromDebtFund(Creditor storage self) internal{
        self.alreadyGetFromDebtFund = true;
    }

    function getGetAlreadyFromdebtFund(Creditor storage self) view  internal returns(bool){
        return self.alreadyGetFromDebtFund;
    }
}
