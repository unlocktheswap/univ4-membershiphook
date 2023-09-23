// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {PoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolModifyPositionTest} from "@uniswap/v4-core/contracts/test/PoolModifyPositionTest.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {PoolSwapTest} from "@uniswap/v4-core/contracts/test/PoolSwapTest.sol";
import {PoolDonateTest} from "@uniswap/v4-core/contracts/test/PoolDonateTest.sol";
import {MembershipHook} from "../src/MembershipHook.sol";
import {IPublicLock} from "../src/interfaces/IPublicLock.sol";
import {HookMiner} from "../test/utils/HookMiner.sol";

/// @notice Forge script for deploying v4 & hooks to **anvil**
contract InitializeNewPool is Script {
    address constant CREATE2_DEPLOYER =
        address(0x4e59b44847b379578588920cA78FbF26c0B4956C);

    IPoolManager public poolManager;
    IHooks public hookContract;
    IPublicLock public lockContract;

    address public token0;
    address public token1;

    function setUp(address _poolManager, address _hookContract, address _lockContract, address _token0, address _token1) public {
        poolManager = IPoolManager(_poolManager);
        hookContract = IHooks(_hookContract);
        lockContract = IPublicLock(_lockContract);

        token0 = _token0;
        token1 = _token1;
    }

    function run() public {
        // Hardcode with anvil private key since we'll only deploy there
        vm.startBroadcast(
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        );

        console2.log("A");

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(token0), 
            currency1: Currency.wrap(token1), 
            fee: 3000, 
            hooks: IHooks(address(0)), 
            tickSpacing: 10
        });

        console2.log("B");

        uint160 sqrtPriceX96 = 3169126500570573503741758013440;
        bytes memory lockAddressBytes = abi.encodePacked(address(lockContract));

        int24 tick = poolManager.initialize(poolKey, sqrtPriceX96, lockAddressBytes);

        lockContract.addLockManager(address(hookContract));

        vm.stopBroadcast();
    }
}

// Deployment commands:
// anvil --code-size-limit 30000
// forge script script/InitializeNewPool.s.sol:InitializeNewPool --fork-url http://localhost:8545 --broadcast 0x0165878A594ca255338adfa4d48449f69242Eb8F 0x481Dd3192297de5F645f7Cc9407A548b31b88376 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
