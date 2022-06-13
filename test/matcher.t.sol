// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "forge-std/Test.sol";

import {ERC20PresetMinterPauser as ERC20} from "../lib/openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

import "../src/matcher.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant DAI  = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

contract MatcherTest is Test {
    Matcher matcher;
    ERC20 A;
    ERC20 B;
    ERC20 C;
    ERC20 D;
    bytes32 test_order;

    function setUp() public {
        matcher = new Matcher();
        A = new ERC20("Bob", "A");
        B = new ERC20("Dirk", "B");
        C = new ERC20("Greg", "C");
        D = new ERC20("Agnew", "D");
	A.mint(address(this), 100000);
	B.mint(address(this), 100000);
	C.mint(address(this), 100000);
	
	// preapprove matcher for all future swaps
	A.approve(address(matcher), type(uint256).max);
	B.approve(address(matcher), type(uint256).max);
	C.approve(address(matcher), type(uint256).max);
    
	Order memory order = Order(1000, 1700, address(A), address(B));
	matcher.create_order(order);
    }

    function test_approve_create_order() public {
	    Order memory order = Order(1000, 1700, address(D), address(C));
	    D.approve(address(matcher), 1700);
	    matcher.create_order(order);
    }

    function test_create_order() public {
	    Order memory order = Order(1000, 1700, address(B), address(C));
	    //B.approve(address(matcher), 1700);
	    matcher.create_order(order);
    }

    function test_cancel_order() public {
	    matcher.cancel_order(address(A), address(B));
    }

    function test_fill_order() public {
	    matcher.partial_fill_order(address(this), address(A), address(B), 10, 15);
    }

    function test_adjust_order() public {
	    matcher.adjust_order(address(A), address(B), 9, 45);
    }
}
