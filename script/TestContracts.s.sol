// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {MembershipHook} from "../src/MembershipHook.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {IPublicLock} from "../src/interfaces/IPublicLock.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {MockERC20} from "@uniswap/v4-core/test/foundry-tests/utils/MockERC20.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
//import {PoolSwapTest} from "@uniswap/v4-core/contracts/test/PoolSwapTest.sol";
import {PoolSwapTest} from "../src/SwapManager.sol";

contract TestContracts is Script {
    address public hookAddr = 0x48B33193C5Ce70B3A3110bbd0d8b254a61329490;

    address public usdcAddr = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;
    address public wethAddr = 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9;
    address public swapAddr = 0x0165878A594ca255338adfa4d48449f69242Eb8F;
    address public _lockAddr = 0xe082b26cEf079a095147F35c9647eC97c2401B83;

    PoolKey public poolKey;
    uint24 dynamicFee = 0x800000;

    // From TickMath
    uint160 internal constant MIN_PRICE_LIMIT = 4295128739 + 1;
    uint160 internal constant MAX_PRICE_LIMIT =
        1461446703485210103287273052203988822378723970342 - 1;

    //uint160 MIN_PRICE_LIMIT = TickMath.MIN_SQRT_RATIO + 1;
    //uint160 MAX_PRICE_LIMIT = TickMath.MAX_SQRT_RATIO - 1;

    function setUp() public {
        MembershipHook membershipHook = MembershipHook(hookAddr);
        poolKey = PoolKey(
            Currency.wrap(usdcAddr),
            Currency.wrap(wethAddr),
            dynamicFee,
            60,
            membershipHook
        );
    }

    function run() public {
        // Hardcode with anvil private key since we'll only deploy there
        vm.startBroadcast(
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        );
        address anvilAddr = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        MockERC20 usdc = MockERC20(usdcAddr);
        MockERC20 weth = MockERC20(wethAddr);
        PoolSwapTest swapRouter = PoolSwapTest(swapAddr);
        MembershipHook membershipHook = MembershipHook(hookAddr);
        IPublicLock unlockContract = IPublicLock(_lockAddr);

        // Should we do these in initialization script?
        // Approve for liquidity provision
        usdc.approve(
            address(swapRouter),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        weth.approve(
            address(swapRouter),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        usdc.approve(
            address(unlockContract),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        weth.approve(
            address(unlockContract),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );

        uint a = weth.allowance(anvilAddr, address(unlockContract));
        console.log("APPROVED AOUNT", a);

        uint bal = unlockContract.balanceOf(address(this));
        console.log("BALANCE IS", bal);

        PoolSwapTest.TestSettings memory testSettings = PoolSwapTest
            .TestSettings({withdrawTokens: true, settleUsingTransfer: true});

        // Focus on positive test cases
        // Desired logic to test:
        // 1. Can we successfully purchase an NFT?
        // 2. Can we successfully swap?

        /*
        Flow:
        1. Make a swap on the pool, make sure we paid the 2% fee
        2. Purchase the NFT
        3. Make another swap on the pool, make sure it was free
        */

        /*
        ////////////////// 1 - swap
        uint usdc0 = usdc.balanceOf(anvilAddr);
        uint weth0 = weth.balanceOf(anvilAddr);
        console2.log("First swap");
        console2.log(usdc0, weth0);

        // Copying swap logic from HookTest
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: 1 * 10 ** 18,
            sqrtPriceLimitX96: MIN_PRICE_LIMIT
        });

        console2.log("B");

        membershipHook.setAAAddr(address(0));

        //bytes memory hookData = bytes("0x");
        BalanceDelta delta = swapRouter.swap(
            poolKey,
            params,
            testSettings,
            bytes("0x")
        );
        console2.log("Swap done");

        // Not sure what balances will be due to exchange rate...
        console2.log(usdc0 - usdc.balanceOf(anvilAddr));
        console2.log(weth.balanceOf(anvilAddr) - weth0);
        //usdc0 = usdc.balanceOf(anvilAddr);
        //weth0 = weth.balanceOf(anvilAddr);
        console2.log(usdc0, weth0);
        console2.log("Purchasing nft");

        ////////////////// 2 - purchase NFT

        console2.log("BEFORE", unlockContract.totalSupply());

        membershipHook.purchaseMembership(poolKey, 100000000, anvilAddr);
        console2.log("AFTER", unlockContract.totalSupply());

        console2.log("Purchased nft");

        ////////////////// 3 - swap again, make sure we got the free fee

        IPoolManager.SwapParams memory params2 = IPoolManager.SwapParams({
            zeroForOne: false,
            amountSpecified: 10000,
            sqrtPriceLimitX96: MAX_PRICE_LIMIT // unlimited impact
        });

        BalanceDelta delta2 = swapRouter.swap(
            poolKey,
            params2,
            testSettings,
            bytes("0x")
        );
        console2.log("Second swap");
        */

        vm.stopBroadcast();
    }
}

// Deployment commands:
// anvil --code-size-limit 30000
// forge script script/InitializeContacts.s.sol:InitializeScript --fork-url http://localhost:8545 --broadcast
