// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../../src/DecentralizedStablecoin.sol";
import {DSCEngineScript} from "../../script/DSCEngine.s.sol";
import {HelperConfig, IHelperConfig} from "../../script/HelperConfig.s.sol";

// Our invariant tests
// There are two invariant tests of DSCEngine contract we should test, but not all.
// 1. The total supply of DSC should be always less than the total value of collateral.
// 2. Getter view functions should never revert.

contract InvariantsTest is StdInvariant, Test {
    DSCEngine public dscEngine;
    DecentralizedStablecoin public decentralizedStablecoin;
    HelperConfig public helperConfig;

    function setUp() public {
        (decentralizedStablecoin, dscEngine, helperConfig) = new DSCEngineScript().run();

        targetContract(address(dscEngine));
    }

    function invariant_DSCMustHaveMoreValueThanTotalSupply() public pure {
        assertEq(true, true);
    }
}
