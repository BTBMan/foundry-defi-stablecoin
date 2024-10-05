// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {DecentralizedStablecoin} from "../src/DecentralizedStablecoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DSCEngineScript is Script, HelperConfig {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (DecentralizedStablecoin decentralizedStablecoin, DSCEngine dscEngine) {
        tokenAddresses = [activeNetworkConfig.weth, activeNetworkConfig.wbtc];
        priceFeedAddresses = [activeNetworkConfig.wethUSDPriceFeed, activeNetworkConfig.wbtcUSDPriceFeed];

        vm.startBroadcast(activeNetworkConfig.deployerKey);
        decentralizedStablecoin = new DecentralizedStablecoin();
        dscEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(decentralizedStablecoin));

        decentralizedStablecoin.transferOwnership(address(dscEngine));
        vm.stopBroadcast();
    }
}
