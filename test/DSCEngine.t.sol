// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../src/DecentralizedStablecoin.sol";
import {DSCEngineScript} from "../script/DSCEngine.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DSCEngineTest is Test {
    HelperConfig.NetworkConfig public activeNetworkConfig;

    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    DSCEngine public dscEngine;
    DecentralizedStablecoin public decentralizedStablecoin;
    DSCEngineScript public dscEngineScript;

    address public user = makeAddr("user");

    function setUp() public {
        dscEngineScript = new DSCEngineScript();
        (decentralizedStablecoin, dscEngine, activeNetworkConfig) = dscEngineScript.run();
        ERC20Mock(activeNetworkConfig.weth).mint(user, STARTING_ERC20_BALANCE);
    }

    function testRevertsIfTokenLengthDoesntMatchPriceFeed() public {
        tokenAddresses.push(activeNetworkConfig.weth);
        priceFeedAddresses.push(activeNetworkConfig.wethUSDPriceFeed);
        priceFeedAddresses.push(activeNetworkConfig.wbtcUSDPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(decentralizedStablecoin));
    }

    function testGetUSDValue() public view {
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
