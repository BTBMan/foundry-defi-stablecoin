// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../src/DecentralizedStablecoin.sol";
import {DSCEngineScript} from "../script/DSCEngine.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DSCEngineTest is Test {
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    DSCEngine public dscEngine;
    DecentralizedStablecoin public decentralizedStablecoin;
    HelperConfig.NetworkConfig public activeNetworkConfig;

    address public user = makeAddr("user");

    function setUp() public {
        (decentralizedStablecoin, dscEngine, activeNetworkConfig) = new DSCEngineScript().run();
    }

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dscEngine.getUSDValue(activeNetworkConfig.weth, ethAmount);

        assertEq(expectedUsd, actualUsd);
    }

    function testRevertIfCollateralZero() public {
        vm.startPrank(user);
        ERC20Mock(activeNetworkConfig.weth).approve(address(dscEngine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__needsMoreThanZero.selector);
        dscEngine.depositCollateral(activeNetworkConfig.weth, 0);
        vm.stopPrank();
    }
}
