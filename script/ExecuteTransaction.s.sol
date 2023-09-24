// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import {ISafe} from "../src/interfaces/SafeGlobal/ISafe.sol";
import {MembershipHook} from "../src/MembershipHook.sol";
import {ISafeProtocolManager, IPlugin} from "../src/interfaces/SafeGlobal/ISafeProtocol.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";

/// @notice Forge script for deploying v4 & hooks to **anvil**
contract ExecuteTransaction is Script {
    function setUp() public {}

    function run() public {
        // Hardcode with anvil private key since we'll only deploy there
        vm.startBroadcast(
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        );
        // From SafeManager/packages/protocol-kit
        ISafe safe = ISafe(0x8464135c8F25Da09e49BC8782676a84730C318bC);

        // 'FixedManager' from Safe-AA
        ISafeProtocolManager manager = ISafeProtocolManager(
            0xA7221558A4E2203821ad65ff820366194eA9C4E6
        );

        //uint160 MAX_PRICE_LIMIT = 1461446703485210103287273052203988822378723970342 -
        //        1;

        address AAsender = address(manager);
        address nftAddress = 0xe082b26cEf079a095147F35c9647eC97c2401B83;
        uint160 sqrtPriceLimitX96 = 4295128739 + 1;
        address token0 = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;
        address token1 = 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9;

        address hookAddr = 0x48B33193C5Ce70B3A3110bbd0d8b254a61329490;
        MembershipHook membershipHook = MembershipHook(hookAddr);
        PoolKey memory poolKey = PoolKey(
            Currency.wrap(token0),
            Currency.wrap(token1),
            0x800000,
            60,
            membershipHook
        );

        bytes memory data = abi.encode(
            AAsender,
            nftAddress,
            // freeSwap
            false,
            poolKey,
            //zeroForOne,
            true,
            //amountSpecified,
            1000,
            sqrtPriceLimitX96,
            // swap contract?
            0x0165878A594ca255338adfa4d48449f69242Eb8F
        );

        // Doesn't change?
        console2.log("C AS", address(this), msg.sender);

        membershipHook.setAAAddr(AAsender);
        console2.log("B AS");

        // RelayPlugin
        IPlugin(0x92Cf6DE768e642104603C6eD299AdEd190355dFd).executeFromPlugin(
            manager,
            safe,
            data
        );
    }
}
/*
deploying "TokenCallbackHandler_SV1_4_1" (tx: 0x57d5062244c077930135b419385e8099e6cfe55370fa3b48f598425fe5fe8d62)...: deployed at 0xc6F478FE6Ea0544Fed3181087BE0F2E5722B46Bc with 473820 gas
(base) ➜  protocol-kit git:(main)



------------------------
sending eth to create2 contract deployer address (0xE1CB04A0fA36DdD16a06ea828007E35e1a3cBC37) (tx: 0x8f7515211acac460c6912a3288d9a32f86234b5c0ef645c39e34370faedcd23f)...
deploying create2 deployer contract (at 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7) using deterministic deployment (https://github.com/Arachnid/deterministic-deployment-proxy) (tx: 0x41a6b731f53cf45627c3976abcb9ecd52fb2142f8f6fbbff4e0bb54a9b3667bc)...
deploying "RelayPlugin" (tx: 0x138778edf4fec701318ea3c035a97a7c804a85aeaf8f7c8ceb8da93dfdf1c33d)...: deployed at 0xce139dc3BDF6592b63d307Ec94Cb00bD2180914E with 2151849 gas
deploying "WhitelistPlugin" (tx: 0xa996093d499030937d569f412631e9575f7e27ff9e4e54de29341690aa26189d)...: deployed at 0x975C0579c76C61192EE5d2d5E38A86a08D81FFaa with 1637291 gas
deploying "RecoveryWithDelayPlugin" (tx: 0xbb47f4aab38a0a7343d29d6d6ae182156bfc5935d4cf4e8a5b4e29fc8ff405bf)...: deployed at 0x5B129a49EA0A8fF204c4179D9887E29F151D1857 with 1898326 gas
deploying "FixedManager" (tx: 0x00a58bcf18cb41af89447247dd999b27db371db861489d3e81a06139bea3d30a)...: deployed at 0xA7221558A4E2203821ad65ff820366194eA9C4E6 with 286538 gas



*/

// Deployment commands:
// anvil --code-size-limit 30000
// forge script script/ExecuteTransaction.s.sol:ExecuteTransaction --fork-url http://localhost:8545 --broadcast
