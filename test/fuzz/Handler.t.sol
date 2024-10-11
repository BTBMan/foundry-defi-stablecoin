// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../../src/DecentralizedStablecoin.sol";

contract HandlerTest is StdInvariant, Test {
    uint96 public constant MAX_DEPOSIT_SIZE = type(uint96).max;

    DSCEngine public dscEngine;
    DecentralizedStablecoin public decentralizedStablecoin;

    ERC20Mock weth;
    ERC20Mock wbtc;

    constructor(DSCEngine _dscEngine, DecentralizedStablecoin _decentralizedStablecoin) {
        dscEngine = _dscEngine;
        decentralizedStablecoin = _decentralizedStablecoin;

        address[] memory collateralAddress = dscEngine.getCollateralTokens();
        weth = ERC20Mock(collateralAddress[0]);
        wbtc = ERC20Mock(collateralAddress[1]);
    }

    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender); // call by msg.sender, not this contract!!!
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(dscEngine), amountCollateral); // dscEngine should be approved

        dscEngine.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
    }

    function mintDSC(uint256 amountDSC) public {
        (uint256 totalDSCMinted, uint256 collateralValueInUSD) = dscEngine.getAccountInformation(msg.sender);
        // Should subtract the DSC we already have
        int256 maxDSCToMint = (int256(collateralValueInUSD) / 2) - int256(totalDSCMinted);
        if (maxDSCToMint < 0) return;

        amountDSC = bound(amountDSC, 0, uint256(maxDSCToMint));
        if (maxDSCToMint == 0) return;

        vm.startPrank(msg.sender);
        dscEngine.mintDSC(amountDSC);
        vm.stopPrank();
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralToRedeem = dscEngine.getCollateralBalanceOfUser(msg.sender, address(collateral));
        amountCollateral = bound(amountCollateral, 0, maxCollateralToRedeem);

        if (amountCollateral == 0) return;

        vm.prank(msg.sender);
        dscEngine.redeemCollateral(address(collateral), amountCollateral);
    }

    function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        }
        return wbtc;
    }
}
