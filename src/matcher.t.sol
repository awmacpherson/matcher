// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./Matcher.sol";

contract MatcherTest is DSTest {
    Matcher matcher;

    function setUp() public {
        matcher = new Matcher();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
