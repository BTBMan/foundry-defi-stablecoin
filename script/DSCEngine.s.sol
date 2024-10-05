// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {DecentralizedStablecoin} from "../src/DecentralizedStablecoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DSCEngineScript is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (DecentralizedStablecoin decentralizedStablecoin, DSCEngine dscEngine) {
        HelperConfig helperConfig = new HelperConfig();
        (address wethUSDPriceFeed, address wbtcUSDPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();

        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUSDPriceFeed, wbtcUSDPriceFeed];

        vm.startBroadcast(deployerKey);
        decentralizedStablecoin = new DecentralizedStablecoin();
        dscEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(decentralizedStablecoin));

        decentralizedStablecoin.transferOwnership(address(dscEngine));
        vm.stopBroadcast();
    }
}
