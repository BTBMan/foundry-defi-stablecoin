// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

contract Example {
    uint256 public alwaysZero = 0;
    uint256 public sign = 0;

    function doStuff(uint256 val) public {
        // if (val == 5) {
        //     alwaysZero = 6;
        // }
        if (sign == 7) {
            alwaysZero = 8;
        }

        sign = val;
    }
}

contract InvariantTest is StdInvariant, Test {
    Example example;

    function setUp() public {
        example = new Example();
        targetContract(address(example));
    }

    function testAlwaysZero(uint256 x) public {
        example.doStuff(x);

        assertEq(example.alwaysZero(), 0);
    }

    function invariant_testAlwaysZero() public view {
        assertEq(example.alwaysZero(), 0);
    }
}
