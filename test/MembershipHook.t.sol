// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {HookTest} from "./utils/HookTest.sol";
import {MembershipHook} from "../src/MembershipHook.sol";
import {IPublicLock} from "../src/interfaces/IPublicLock.sol";
import {HookMiner} from "./utils/HookMiner.sol";

contract MembershipHookTest is HookTest, Deployers, GasSnapshot {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    MembershipHook membershipHook;
    PoolKey poolKey;
    PoolId poolId;

    function setUp() public {
        // Need to create Unlock factory elsewhere
        IPublicLock lockContract = IPublicLock(address(42));
        console2.log("F");

        // creates the pool manager, test tokens, and other utility routers
        HookTest.initHookTestEnv();

        // Deploy the hook to an address with the correct flags
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_INITIALIZE_FLAG
        );

        (address hookAddress, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            0,
            type(MembershipHook).creationCode,
            abi.encode(address(manager))
        );

        console2.log("G");
        membershipHook = new MembershipHook{salt: salt}(
            IPoolManager(address(manager))
        );
        console2.log("Z");
        require(
            address(membershipHook) == hookAddress,
            "MembershipHookTest: hook address mismatch"
        );

        // Set our fee to be the DYNAMIC_FEE_FLAG, we won't use whatever the value is anyways
        uint24 dynamicFee = 0x800000;
        console2.log("X");

        // Create the pool
        poolKey = PoolKey(
            Currency.wrap(address(token0)),
            Currency.wrap(address(token1)),
            dynamicFee,
            60,
            IHooks(membershipHook)
        );

        console2.log("H");
        poolId = poolKey.toId();

        address lockAddress = address(12345);
        bytes memory hookData = abi.encodePacked(lockAddress);
        // manager.initialize(poolKey, SQRT_RATIO_1_1, ZERO_BYTES);
        manager.initialize(poolKey, SQRT_RATIO_1_1, hookData);
        console2.log("i");

        // Provide liquidity to the pool
        modifyPositionRouter.modifyPosition(
            poolKey,
            IPoolManager.ModifyPositionParams(-60, 60, 10 ether)
        );
        modifyPositionRouter.modifyPosition(
            poolKey,
            IPoolManager.ModifyPositionParams(-120, 120, 10 ether)
        );
        modifyPositionRouter.modifyPosition(
            poolKey,
            IPoolManager.ModifyPositionParams(
                TickMath.minUsableTick(60),
                TickMath.maxUsableTick(60),
                10 ether
            )
        );
        console2.log("DONE");
    }

    function testMembershipHook() public {
        // positions were created in setup()

        // Make sure our dynamic fee was applied (with hardcoded non-member fee)
        uint bal0pre = Currency.wrap(address(token0)).balanceOf(address(this));
        uint bal1pre = Currency.wrap(address(token1)).balanceOf(address(this));

        // Perform a test swap //
        int256 amount = 100000;
        bool zeroForOne = true;
        swap(poolKey, amount, zeroForOne);
        // ------------------- //

        uint bal0post = Currency.wrap(address(token0)).balanceOf(address(this));
        uint bal1post = Currency.wrap(address(token1)).balanceOf(address(this));
        uint diff0 = bal0pre - bal0post;
        uint diff1 = bal1post - bal1pre;
        uint feePaid = diff0 - diff1;

        // 2% of 100000 is 2000, but looks like it rounds up one
        // console2.log(diff0);
        // console2.log(diff1);
        assertGe(feePaid, 2000);
    }
}
