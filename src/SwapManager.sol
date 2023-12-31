// SPDX-License-Identifier: UNLICENSED
// Copied and modified (to pass through hookData) from v4-core/test/PoolSwapTest.sol
pragma solidity ^0.8.20;

//import {CurrencyLibrary, Currency} from "../types/Currency.sol";
//import {IERC20Minimal} from "../interfaces/external/IERC20Minimal.sol";
//import {ILockCallback} from "../interfaces/callback/ILockCallback.sol";
//import {IPoolManager} from "../interfaces/IPoolManager.sol";
//import {BalanceDelta} from "../types/BalanceDelta.sol";
//import {PoolKey} from "../types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {IERC20Minimal} from "@uniswap/v4-core/contracts/interfaces/external/IERC20Minimal.sol";
import {ILockCallback} from "@uniswap/v4-core/contracts/interfaces/callback/ILockCallback.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";

import "forge-std/console2.sol";

contract PoolSwapTest is ILockCallback {
    using CurrencyLibrary for Currency;

    IPoolManager public immutable manager;

    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    struct CallbackData {
        address sender;
        TestSettings testSettings;
        PoolKey key;
        IPoolManager.SwapParams params;
        bytes hookData;
    }

    struct TestSettings {
        bool withdrawTokens;
        bool settleUsingTransfer;
    }

    function swap(
        PoolKey memory key,
        IPoolManager.SwapParams memory params,
        TestSettings memory testSettings,
        bytes calldata hookData
    ) external payable returns (BalanceDelta delta) {
        console2.log("PoolSwapTestcalled");
        delta = abi.decode(
            manager.lock(
                abi.encode(
                    CallbackData(
                        msg.sender,
                        testSettings,
                        key,
                        params,
                        hookData
                    )
                )
            ),
            (BalanceDelta)
        );
        console2.log("got delta");

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            CurrencyLibrary.NATIVE.transfer(msg.sender, ethBalance);
        }
    }

    function lockAcquired(
        bytes calldata rawData
    ) external returns (bytes memory) {
        console2.log("lockAcquired");
        require(msg.sender == address(manager));
        console2.log("lock ok...");

        CallbackData memory data = abi.decode(rawData, (CallbackData));

        console2.log("data is ok...");
        BalanceDelta delta = manager.swap(data.key, data.params, data.hookData);

        console2.log("DELTA AMOUNT0", delta.amount0());
        console2.log("DELTA AMOUNT1", delta.amount1());

        if (data.params.zeroForOne) {
            if (delta.amount0() > 0) {
                if (data.testSettings.settleUsingTransfer) {
                    if (data.key.currency0.isNative()) {
                        manager.settle{value: uint128(delta.amount0())}(
                            data.key.currency0
                        );
                    } else {
                        IERC20Minimal(Currency.unwrap(data.key.currency0))
                            .transferFrom(
                                data.sender,
                                address(manager),
                                uint128(delta.amount0())
                            );
                        manager.settle(data.key.currency0);
                    }
                } else {
                    // the received hook on this transfer will burn the tokens
                    manager.safeTransferFrom(
                        data.sender,
                        address(manager),
                        uint256(uint160(Currency.unwrap(data.key.currency0))),
                        uint128(delta.amount0()),
                        ""
                    );
                }
            }
            if (delta.amount1() < 0) {
                if (data.testSettings.withdrawTokens) {
                    manager.take(
                        data.key.currency1,
                        data.sender,
                        uint128(-delta.amount1())
                    );
                } else {
                    manager.mint(
                        data.key.currency1,
                        data.sender,
                        uint128(-delta.amount1())
                    );
                }
            }
        } else {
            if (delta.amount1() > 0) {
                if (data.testSettings.settleUsingTransfer) {
                    if (data.key.currency1.isNative()) {
                        manager.settle{value: uint128(delta.amount1())}(
                            data.key.currency1
                        );
                    } else {
                        IERC20Minimal(Currency.unwrap(data.key.currency1))
                            .transferFrom(
                                data.sender,
                                address(manager),
                                uint128(delta.amount1())
                            );
                        manager.settle(data.key.currency1);
                    }
                } else {
                    // the received hook on this transfer will burn the tokens
                    manager.safeTransferFrom(
                        data.sender,
                        address(manager),
                        uint256(uint160(Currency.unwrap(data.key.currency1))),
                        uint128(delta.amount1()),
                        ""
                    );
                }
            }
            if (delta.amount0() < 0) {
                if (data.testSettings.withdrawTokens) {
                    manager.take(
                        data.key.currency0,
                        data.sender,
                        uint128(-delta.amount0())
                    );
                } else {
                    manager.mint(
                        data.key.currency0,
                        data.sender,
                        uint128(-delta.amount0())
                    );
                }
            }
        }

        return abi.encode(delta);
    }
}
