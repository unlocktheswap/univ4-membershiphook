// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {PoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolModifyPositionTest} from "@uniswap/v4-core/contracts/test/PoolModifyPositionTest.sol";
import {PoolDonateTest} from "@uniswap/v4-core/contracts/test/PoolDonateTest.sol";
import {MembershipHook} from "../src/MembershipHook.sol";
import {IPublicLock} from "../src/interfaces/IPublicLock.sol";
import {HookMiner} from "../test/utils/HookMiner.sol";
import {MockERC20} from "@uniswap/v4-core/test/foundry-tests/utils/MockERC20.sol";
//import {PoolSwapTest} from "@uniswap/v4-core/contracts/test/PoolSwapTest.sol";
import {PoolSwapTest} from "../src/SwapManager.sol";

/// @notice Forge script for deploying v4 & hooks to **anvil**
/// @dev This script only works on an anvil RPC because v4 exceeds bytecode limits
contract MembershipHookScript is Script {
    address constant CREATE2_DEPLOYER =
        address(0x4e59b44847b379578588920cA78FbF26c0B4956C);

    function setUp() public {}

    function run() public {
        // Hardcode with anvil private key since we'll only deploy there
        vm.startBroadcast(
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        );

        // vm.broadcast();
        PoolManager manager = new PoolManager(500000);
        // TODO: create Unlock factory
        // IPublicLock lockContract = IPublicLock(address(42));

        // hook contracts must have specific flags encoded in the address
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_INITIALIZE_FLAG
        );

        // Mine a salt that will produce a hook address with the correct flags
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            flags,
            1000,
            type(MembershipHook).creationCode,
            abi.encode(address(manager))
        );

        // Deploy the hook using CREATE2
        // vm.broadcast();
        MembershipHook membershipHook = new MembershipHook{salt: salt}(
            IPoolManager(address(manager))
        );

        require(
            address(membershipHook) == hookAddress,
            "MembershipHookScript: hook address mismatch"
        );

        // Additional helpers for interacting with the pool
        // vm.startBroadcast();

        // These will also mint totalSupply to msg.sender
        uint totalSupply = 10000 ether;
        MockERC20 usdc = new MockERC20("USDC", "USDC", 18, totalSupply);
        MockERC20 weth = new MockERC20("WETH", "WETH", 18, totalSupply);
        require(address(usdc) < address(weth), "Bad address sorting");

        PoolModifyPositionTest pmpt = new PoolModifyPositionTest(
            IPoolManager(address(manager))
        );
        PoolSwapTest pst = new PoolSwapTest(IPoolManager(address(manager)));
        new PoolDonateTest(IPoolManager(address(manager)));

        console2.log("------------ ADDRESSES! --------- ");
        console2.log("USDC", address(usdc));
        console2.log("WETH", address(weth));
        console2.log("SwapRouter", address(pst));
        console2.log("ModifyPositionRouter", address(pmpt));
        console2.log("MembershipHook", address(membershipHook));
        console2.log("PoolManager", address(manager));

        vm.stopBroadcast();
    }
}

// Deployment commands:
// anvil --code-size-limit 30000
// forge script script/MembershipHook.s.sol:MembershipHookScript --fork-url http://localhost:8545 --broadcast
