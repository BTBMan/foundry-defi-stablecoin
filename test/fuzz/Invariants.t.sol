// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../../src/DecentralizedStablecoin.sol";
import {DSCEngineScript} from "../../script/DSCEngine.s.sol";
import {HelperConfig, IHelperConfig} from "../../script/HelperConfig.s.sol";
import {HandlerTest} from "./Handler.t.sol";

// Our invariant tests
// There are two invariant tests of DSCEngine contract we should test, but not all.
// 1. The total supply of DSC should be always less than the total value of collateral.
// 2. Getter view functions should never revert.

contract InvariantTest is StdInvariant, Test, IHelperConfig {
    NetworkConfig public activeNetworkConfig;

    DSCEngine public dscEngine;
    DecentralizedStablecoin public decentralizedStablecoin;
    HelperConfig public helperConfig;
    HandlerTest public handlerTest;

    function setUp() public {
        (decentralizedStablecoin, dscEngine, helperConfig) = new DSCEngineScript().run();
        activeNetworkConfig = helperConfig.getActiveNetworkConfig();

        handlerTest = new HandlerTest(dscEngine, decentralizedStablecoin);

        targetContract(address(handlerTest));
    }

    function invariant_DSCMustHaveMoreValueThanTotalSupply() public view {
        uint256 totalSupply = decentralizedStablecoin.totalSupply();
        uint256 totalWETHDeposited = IERC20(activeNetworkConfig.weth).balanceOf(address(dscEngine));
        uint256 totalWBTCDeposited = IERC20(activeNetworkConfig.wbtc).balanceOf(address(dscEngine));

        uint256 wethValue = dscEngine.getUSDValue(activeNetworkConfig.weth, totalWETHDeposited);
        uint256 wbtcValue = dscEngine.getUSDValue(activeNetworkConfig.wbtc, totalWBTCDeposited);

        assertLe(totalSupply, wethValue + wbtcValue);
    }
}
