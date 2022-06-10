// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import {ERC20PresetMinterPauser as ERC20} from "../lib/openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

import "./Matcher.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant DAI  = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

contract MatcherTest is DSTest {
    Matcher matcher;
    ERC20 A;
    ERC20 B;

    function setUp() public {
        matcher = new Matcher();
        A = new ERC20("Bob", "A");
        B = new ERC20("Dirk", "B");
	B.mint(address(this), 100000);
	
	// preapprove matcher for all future swaps
	B.approve(address(matcher), type(uint256).max);
    }

    function test_approve_only() public {
	    B.approve(address(matcher), 33533383847);
    }
    
    function test_create_order() public {
	    Order memory order = Order(1000, 1700, address(this), address(A), address(B));
	    //B.approve(address(matcher), 1700);
	    uint id = uint(matcher.create_order(order));
	    assertTrue(id>0);
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
	assertEq(A.allowance(address(this), address(matcher)), 0);
        assertTrue(true);
    }
}
