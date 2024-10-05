// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "@chainlink/contracts/v0.8/tests/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address wethUSDPriceFeed;
        address wbtcUSDPriceFeed;
        address weth;
        address wbtc;
        uint256 deployerKey;
    }

    uint8 public constant DECIMALS = 8;
    int256 public constant ETC_USD_PRICE = 2000e8;
    int256 public constant BTC_USD_PRICE = 3000e8;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        NetworkConfig memory config = NetworkConfig({
            wethUSDPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcUSDPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            deployerKey: vm.envUint("REAL_PRIVATE_KEY")
        });

        return config;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.wethUSDPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockWETHUSDPriceFeed = new MockV3Aggregator(DECIMALS, ETC_USD_PRICE);
        MockV3Aggregator mockWBTCUSDPriceFeed = new MockV3Aggregator(DECIMALS, BTC_USD_PRICE);
        ERC20Mock mockWETH = new ERC20Mock();
        ERC20Mock mockWBTC = new ERC20Mock();
        vm.stopBroadcast();

        NetworkConfig memory config = NetworkConfig({
            wethUSDPriceFeed: address(mockWETHUSDPriceFeed),
            wbtcUSDPriceFeed: address(mockWBTCUSDPriceFeed),
            weth: address(mockWETH),
            wbtc: address(mockWBTC),
            deployerKey: vm.envUint("PRIVATE_KEY")
        });

        return config;
    }
}
