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
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {MockERC20} from "@uniswap/v4-core/test/foundry-tests/utils/MockERC20.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";

/// @notice Forge script for deploying v4 & hooks to **anvil**
contract InitializeNewPool is Script {
    using PoolIdLibrary for PoolKey;
    address constant CREATE2_DEPLOYER =
        address(0x4e59b44847b379578588920cA78FbF26c0B4956C);

    IPoolManager public poolManager;
    IHooks public hookContract;
    IPublicLock public lockContract1;
    IPublicLock public lockContract2;
    PoolModifyPositionTest public modifyPositionRouter;

    address public token0;
    address public token1;

    function setUp() public {
        address _poolManager = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;

        address _hookContract = 0x488bF5df107Ab59151abe28294d3cF402DE871B2;
        address _lockContract1 = 0xe082b26cEf079a095147F35c9647eC97c2401B83;
        address _lockContract2 = 0x788F1E4a99fa704Edb43fAE71946cFFDDcC16ccB;
        address _pmpt = 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707;
        address _token0 = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;
        address _token1 = 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9;

        poolManager = IPoolManager(_poolManager);
        hookContract = IHooks(_hookContract);
        lockContract1 = IPublicLock(_lockContract1);
        lockContract2 = IPublicLock(_lockContract2);
        modifyPositionRouter = PoolModifyPositionTest(_pmpt);

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
            fee: 0x800000,
            hooks: IHooks(address(hookContract)),
            tickSpacing: 60
        });

        console2.log("B");

        // Starting price of 1600 for ETH/USDT pool
        uint160 sqrtPriceX96 = 3169126500570573503741758013440;
        bytes memory lockAddressBytes = abi.encodePacked(
            address(lockContract1),
            address(lockContract2)
        );

        int24 tick = poolManager.initialize(
            poolKey,
            sqrtPriceX96,
            lockAddressBytes
        );
        console2.log("C");

        // Sanity check for successful initialization
        PoolId id = poolKey.toId();
        (
            uint160 _sqrtPriceX96,
            int24 _tick,
            uint8 protocolSwapFee,
            uint8 protocolWithdrawFee,
            uint8 hookSwapFee,
            uint8 hookWithdrawFee
        ) = poolManager.getSlot0(id);
        console2.log("GOT SQRT PRICE", _sqrtPriceX96);

        // Approve for liquidity provision
        MockERC20(token0).approve(address(modifyPositionRouter), 100 ether);
        MockERC20(token1).approve(address(modifyPositionRouter), 100 ether);
        // Make big stake across entire range
        int256 amount = 1 ether;
        modifyPositionRouter.modifyPosition(
            poolKey,
            IPoolManager.ModifyPositionParams(
                TickMath.minUsableTick(60),
                TickMath.maxUsableTick(60),
                amount
            )
        );
        console2.log("D");

        bool isOwner = lockContract1.isLockManager(address(hookContract));
        console2.log(isOwner);

        vm.stopBroadcast();
    }
}

// Deployment commands:
// anvil --code-size-limit 30000
// forge script script/InitializeNewPool.s.sol:InitializeNewPool --fork-url http://localhost:8545 --broadcast 0x0165878A594ca255338adfa4d48449f69242Eb8F 0x481Dd3192297de5F645f7Cc9407A548b31b88376 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
