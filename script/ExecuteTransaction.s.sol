// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";


/// @notice Forge script for deploying v4 & hooks to **anvil**
contract ExecuteTransaction is Script {
    
    function setUp() public {}

    function run() public {
        // Hardcode with anvil private key since we'll only deploy there
        vm.startBroadcast(
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        );

        ISafeProtocolManager manager = ISafeProtocolManager(address(0));
        ISafe safe = ISafe(address(0));

        address AAsender = address(0);
        address nftAddress = address(0);
        address v4Hook = address(0);
        address token0 = address(0);
        address token1 = address(0);
        bool freeSwap = false;
        bool zeroForOne = false;
        int256 amountSpecified = 0;
        uint160 sqrtPriceLimitX96 = 0;

        bytes memory data = abi.encodePacked(AAsender, nftAddress, freeSwap, v4Hook, token0, token1, zeroForOne, amountSpecified, sqrtPriceLimitX96);

        address relayPlugin = address(0);

        IRelayPlugin(relayPlugin).executeFromPlugin(manager, safe, data);
    }
}

// Deployment commands:
// anvil --code-size-limit 30000
// forge script script/InitializeNewPool.s.sol:InitializeNewPool --fork-url http://localhost:8545 --broadcast 0x0165878A594ca255338adfa4d48449f69242Eb8F 0x481Dd3192297de5F645f7Cc9407A548b31b88376 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
