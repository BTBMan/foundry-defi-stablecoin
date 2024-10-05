// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../src/DecentralizedStablecoin.sol";
import {DSCEngineScript} from "../script/DSCEngine.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DSCEngineTest is Test {
    DSCEngine public dscEngine;
    DecentralizedStablecoin public decentralizedStablecoin;
    HelperConfig.NetworkConfig public activeNetworkConfig;

    function setUp() public {
        (decentralizedStablecoin, dscEngine, activeNetworkConfig) = new DSCEngineScript().run();
    }

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dscEngine.getUSDValue(activeNetworkConfig.weth, ethAmount);

        assertEq(expectedUsd, actualUsd);
    }
}
