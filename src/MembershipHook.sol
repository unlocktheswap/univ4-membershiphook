// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseHook} from "v4-periphery/BaseHook.sol";

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";

contract MembershipHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    uint256 public beforeSwapCount;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return
            Hooks.Calls({
                beforeInitialize: false,
                afterInitialize: false,
                beforeModifyPosition: false,
                afterModifyPosition: false,
                beforeSwap: true,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false
            });
    }

    function beforeSwap(
        address,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        bytes calldata
    ) external override returns (bytes4) {
        beforeSwapCount++;
        return BaseHook.beforeSwap.selector;
    }

    /// @notice Returns the dynamic fee that we'll charge on swaps: free for members, 2% for others
    function getFee(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata data
    ) external returns (uint24 newFee) {
        bool hasMembership = false;
        if (hasMembership) {
            return 0;
        }
        // 2%
        return 20000;
    }
}
