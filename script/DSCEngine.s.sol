// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {DecentralizedStablecoin} from "../src/DecentralizedStablecoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig, IHelperConfig} from "./HelperConfig.s.sol";

contract DSCEngineScript is Script, IHelperConfig {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run()
        external
        returns (DecentralizedStablecoin decentralizedStablecoin, DSCEngine dscEngine, HelperConfig helperConfig)
    {
        helperConfig = new HelperConfig();
        NetworkConfig memory activeNetworkConfig = helperConfig.getActiveNetworkConfig();

        tokenAddresses = [activeNetworkConfig.weth, activeNetworkConfig.wbtc];
        priceFeedAddresses = [activeNetworkConfig.wethUSDPriceFeed, activeNetworkConfig.wbtcUSDPriceFeed];

        vm.startBroadcast();
        decentralizedStablecoin = new DecentralizedStablecoin();
        dscEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(decentralizedStablecoin));

        decentralizedStablecoin.transferOwnership(address(dscEngine));
        vm.stopBroadcast();

        return (decentralizedStablecoin, dscEngine, helperConfig);
    }
}
