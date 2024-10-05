// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../src/DecentralizedStablecoin.sol";
import {DSCEngineScript} from "../script/DSCEngine.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DSCEngineTest is Test, HelperConfig {
    DSCEngine public dscEngine;
    DecentralizedStablecoin public decentralizedStablecoin;

    function setUp() public {
        (decentralizedStablecoin, dscEngine) = new DSCEngineScript().run();
    }

    function test() public view {
        console.log(activeNetworkConfig.wethUSDPriceFeed);
    }
}
