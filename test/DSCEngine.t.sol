// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../src/DecentralizedStablecoin.sol";
import {DSCEngineScript} from "../script/DSCEngine.s.sol";
import {HelperConfig, IHelperConfig} from "../script/HelperConfig.s.sol";

contract DSCEngineTest is Test, IHelperConfig {
    NetworkConfig public activeNetworkConfig;

    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    DSCEngine public dscEngine;
    DecentralizedStablecoin public decentralizedStablecoin;
    HelperConfig public helperConfig;
    DSCEngineScript public dscEngineScript;

    address public user = makeAddr("user");

    modifier depositedCollateral() {
        vm.startPrank(user);
        ERC20Mock(activeNetworkConfig.weth).approve(address(dscEngine), AMOUNT_COLLATERAL);

        dscEngine.depositCollateral(activeNetworkConfig.weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function setUp() public {
        dscEngineScript = new DSCEngineScript();
        (decentralizedStablecoin, dscEngine, helperConfig) = dscEngineScript.run();

        activeNetworkConfig = helperConfig.getActiveNetworkConfig();

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

    function testGetTokenAmountFromUSD() public view {
        uint256 usdAmount = 2000 ether;
        uint256 expectedAmount = 1 ether;
        uint256 actualAmount = dscEngine.getTokenAmountFromUSD(activeNetworkConfig.weth, usdAmount);

        assertEq(expectedAmount, actualAmount);
    }

    function testRevertIfCollateralZero() public {
        vm.startPrank(user);
        vm.expectRevert(DSCEngine.DSCEngine__needsMoreThanZero.selector);
        dscEngine.depositCollateral(activeNetworkConfig.weth, 0);
        vm.stopPrank();
    }

    function testRevertWithUnapprovedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock();

        vm.startPrank(user);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dscEngine.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDSCMinted, uint256 collateralValueInUSD) = dscEngine.getAccountInformation(user);
        uint256 expectCollateralAmount = dscEngine.getTokenAmountFromUSD(activeNetworkConfig.weth, collateralValueInUSD);

        assertEq(totalDSCMinted, 0);
        assertEq(AMOUNT_COLLATERAL, expectCollateralAmount);
    }

    function testCalculateHealthFactor() public view {
        uint256 amountDSC = 2000 ether;
        uint256 health = 1 ether;
        // $x * 50 / 100 = $2000 DSC
        // $x = $2000 DSC / 50 * 100
        uint256 collateralValueInUSD =
            amountDSC / dscEngine.getLiquidationThreshold() * dscEngine.getLiquidationPrecision();
        uint256 goodHealth = dscEngine.getCalculateHealthFactor(amountDSC, collateralValueInUSD);
        uint256 badHealth = dscEngine.getCalculateHealthFactor(amountDSC, collateralValueInUSD - 1);

        assertEq(goodHealth, health);
        assertLe(badHealth, health);
    }

    function testRevertIfMintZeroDSC() public {
        vm.startPrank(user);
        vm.expectRevert(DSCEngine.DSCEngine__needsMoreThanZero.selector);
        dscEngine.mintDSC(0);
        vm.stopPrank();
    }
}
