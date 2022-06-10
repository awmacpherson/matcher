// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./Matcher.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant DAI  = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

contract MatcherTest is DSTest {
    Matcher matcher;

    function setUp() public {
        matcher = new Matcher();
    }
    
    function test_create_order() public {
	    Order memory order = Order(1 ether, 1700, address(this), WETH, DAI);
	    bytes32 id = matcher.create_order(order);
	    assertTrue(true);
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
