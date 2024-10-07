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
    uint256 public constant AMOUNT_DSC_TO_MINT = 5 ether;

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    DSCEngine public dscEngine;
    DecentralizedStablecoin public decentralizedStablecoin;
    HelperConfig public helperConfig;
    DSCEngineScript public dscEngineScript;

    address public user = makeAddr("user");

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(address indexed from, address indexed to, address indexed token, uint256 amount);

    modifier depositedCollateral() {
        vm.startPrank(user);
        ERC20Mock(activeNetworkConfig.weth).approve(address(dscEngine), AMOUNT_COLLATERAL);

        dscEngine.depositCollateral(activeNetworkConfig.weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    modifier depositedCollateralAndMintDSC() {
        vm.startPrank(user);
        ERC20Mock(activeNetworkConfig.weth).approve(address(dscEngine), AMOUNT_COLLATERAL);

        dscEngine.depositCollateralAndMintDSC(activeNetworkConfig.weth, AMOUNT_COLLATERAL, AMOUNT_DSC_TO_MINT);
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

    function revertIfHealthFactorIsBroken() public {
        vm.startPrank(user);
        ERC20Mock(activeNetworkConfig.weth).approve(address(dscEngine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__BreaksHealthFactor.selector);
        dscEngine.depositCollateralAndMintDSC(activeNetworkConfig.weth, AMOUNT_COLLATERAL, AMOUNT_DSC_TO_MINT + 1);

        uint256 amountCollateralDeposited = dscEngine.getCollateralDeposited(user, activeNetworkConfig.weth);
        uint256 amountDSCMinted = dscEngine.getDSCMinted(user);
        uint256 userDSCBalance = decentralizedStablecoin.balanceOf(user);
        uint256 userWETHBalance = ERC20Mock(activeNetworkConfig.weth).balanceOf(user);

        assertEq(amountCollateralDeposited, 0);
        assertEq(amountDSCMinted, 0);
        assertEq(userDSCBalance, 0);
        assertEq(userWETHBalance, AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDSCMinted, uint256 collateralValueInUSD) = dscEngine.getAccountInformation(user);
        uint256 expectCollateralAmount = dscEngine.getTokenAmountFromUSD(activeNetworkConfig.weth, collateralValueInUSD);

        assertEq(totalDSCMinted, 0);
        assertEq(AMOUNT_COLLATERAL, expectCollateralAmount);
    }

    function testGetAccountCollateralValue() public depositedCollateral {
        uint256 expectedValue = (AMOUNT_COLLATERAL * 2000 ether) / 1 ether;
        uint256 collaterValueInUSD = dscEngine.getAccountCollateralValue(user);

        assertEq(expectedValue, collaterValueInUSD);
    }

    function testEmitEventWhenDepositCollateral() public {
        vm.startPrank(user);
        ERC20Mock(activeNetworkConfig.weth).approve(address(dscEngine), AMOUNT_COLLATERAL);

        vm.expectEmit(true, true, true, false, address(dscEngine));
        emit CollateralDeposited(user, activeNetworkConfig.weth, AMOUNT_COLLATERAL);

        dscEngine.depositCollateral(activeNetworkConfig.weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testCalculateHealthFactor() public view {
        uint256 dscAmount = 2000 ether;
        uint256 health = 1 ether;
        // $x * 50 / 100 = $2000 DSC
        // $x = $2000 DSC / 50 * 100
        uint256 collateralValueInUSD =
            dscAmount / dscEngine.getLiquidationThreshold() * dscEngine.getLiquidationPrecision();
        uint256 goodHealth = dscEngine.getCalculateHealthFactor(dscAmount, collateralValueInUSD);
        uint256 badHealth = dscEngine.getCalculateHealthFactor(dscAmount, collateralValueInUSD - 1);

        assertGe(goodHealth, health);
        assertLe(badHealth, health);
    }

    function testGetHealthFactor() public depositedCollateral {
        uint256 expectedHealth = 1;
        uint256 actualHealth = dscEngine.getHealthFactor(user);

        assertLe(expectedHealth, actualHealth);
    }

    function testRevertIfMintZeroDSC() public {
        vm.startPrank(user);
        vm.expectRevert(DSCEngine.DSCEngine__needsMoreThanZero.selector);
        dscEngine.mintDSC(0);
        vm.stopPrank();
    }

    function testDSCEngineHasCollateralTokenBalanceAfterCollateral() public depositedCollateral {
        uint256 dscEngineBalance = ERC20Mock(activeNetworkConfig.weth).balanceOf(address(dscEngine));

        assertEq(dscEngineBalance, AMOUNT_COLLATERAL);
    }

    function testDepositCollateralAndMintDSC() public depositedCollateralAndMintDSC {
        uint256 amountCollateralDeposited = dscEngine.getCollateralDeposited(user, activeNetworkConfig.weth);
        uint256 amountDSCMinted = dscEngine.getDSCMinted(user);
        uint256 userDSCBalance = decentralizedStablecoin.balanceOf(user);
        uint256 userWETHBalance = ERC20Mock(activeNetworkConfig.weth).balanceOf(user);

        assertEq(amountCollateralDeposited, AMOUNT_COLLATERAL);
        assertEq(amountDSCMinted, AMOUNT_DSC_TO_MINT);
        assertEq(userDSCBalance, AMOUNT_DSC_TO_MINT);
        assertEq(userWETHBalance, 0);
    }

    function testCanBurnDSC() public depositedCollateralAndMintDSC {
        vm.startPrank(user);
        decentralizedStablecoin.approve(address(dscEngine), AMOUNT_COLLATERAL);

        dscEngine.burnDSC(AMOUNT_DSC_TO_MINT);
        vm.stopPrank();

        uint256 amountDSCMinted = dscEngine.getDSCMinted(user);
        uint256 userDSCBalance = decentralizedStablecoin.balanceOf(user);

        assertEq(amountDSCMinted, 0);
        assertEq(userDSCBalance, 0);
    }

    function testCanRedeemCollateral() public depositedCollateral {
        vm.startPrank(user);
        dscEngine.redeemCollateral(activeNetworkConfig.weth, AMOUNT_COLLATERAL);
        vm.stopPrank();

        uint256 amountCollateralDeposited = dscEngine.getCollateralDeposited(user, activeNetworkConfig.weth);
        uint256 userWETHBalance = ERC20Mock(activeNetworkConfig.weth).balanceOf(user);

        assertEq(amountCollateralDeposited, 0);
        assertEq(userWETHBalance, AMOUNT_COLLATERAL);
    }

    function testEmitEventAfterRedeemCollateral() public depositedCollateral {
        vm.startPrank(user);
        vm.expectEmit(true, true, true, true, address(dscEngine));
        emit CollateralRedeemed(user, user, activeNetworkConfig.weth, AMOUNT_COLLATERAL);

        dscEngine.redeemCollateral(activeNetworkConfig.weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testRedeemCollateralForDSC() public depositedCollateralAndMintDSC {
        vm.startPrank(user);
        decentralizedStablecoin.approve(address(dscEngine), AMOUNT_COLLATERAL);

        dscEngine.redeemCollateralForDSC(activeNetworkConfig.weth, AMOUNT_COLLATERAL, AMOUNT_DSC_TO_MINT);
        vm.stopPrank();

        uint256 amountCollateralDeposited = dscEngine.getCollateralDeposited(user, activeNetworkConfig.weth);
        uint256 amountDSCMinted = dscEngine.getDSCMinted(user);
        uint256 userDSCBalance = decentralizedStablecoin.balanceOf(user);
        uint256 userWETHBalance = ERC20Mock(activeNetworkConfig.weth).balanceOf(user);

        assertEq(amountCollateralDeposited, 0);
        assertEq(amountDSCMinted, 0);
        assertEq(userDSCBalance, 0);
        assertEq(userWETHBalance, AMOUNT_COLLATERAL);
    }

    function testRevertIfLiquidateWithZeroDebt() public depositedCollateralAndMintDSC {
        vm.expectRevert(DSCEngine.DSCEngine__needsMoreThanZero.selector);
        dscEngine.liquidate(activeNetworkConfig.weth, user, 0);
    }

    function testRevertIfLiquidateHealthFactorIsOk() public depositedCollateralAndMintDSC {
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorOk.selector);
        dscEngine.liquidate(activeNetworkConfig.weth, user, 1);
    }

    function testRevertIfHealthFactorIsNotImproved() public {
        //
    }
}
