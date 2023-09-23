// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseHook} from "v4-periphery/BaseHook.sol";

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {IPublicLock} from "./interfaces/IPublicLock.sol";

contract MembershipHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    // Interface for the Unlock NFT contract
    IPublicLock public lockContract;
    // Address of the erc20 that has to be used to pay for membership
    address public tokenAddress;

    uint256 public beforeSwapCount;

    constructor(
        IPoolManager _poolManager,
        IPublicLock _lockContract
    ) BaseHook(_poolManager) {
        lockContract = _lockContract;
        tokenAddress = lockContract.tokenAddress();
    }

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
        bool hasMembership = lockContract.balanceOf(msg.sender) == 0;
        if (hasMembership) {
            return 0;
        }
        // 2%
        return 20000;
    }

    /// @notice Purchases a membership and returns the token ID
    function purchaseMembership(
        PoolKey calldata poolKey,
        uint256 value
    ) external payable returns (uint256 tokenId) {
        // parameters for key purchase
        uint256[] memory _values = new uint256[](1);
        _values[0] = value;

        address[] memory _recipients = new address[](1);
        _recipients[0] = msg.sender;

        address[] memory _referrers = new address[](1);
        _referrers[0] = msg.sender;

        address[] memory _keyManagers = new address[](1);
        _keyManagers[0] = msg.sender;

        bytes[] memory _data = new bytes[](1);
        _data[0] = bytes("0x");

        uint256[] memory tokenIds = lockContract.purchase{value: msg.value}(
            _values,
            _recipients,
            _referrers,
            _keyManagers,
            _data
        );

        _withdrawAndDonate(poolKey, value);

        tokenId = tokenIds[0];
    }

    /// @notice Withdraws all funds from the lock and donates them to the pool
    function _withdrawAndDonate(
        PoolKey calldata poolKey,
        uint256 amount
    ) internal returns (BalanceDelta delta) {
        // withdraw all funds from the lock

        lockContract.withdraw(tokenAddress, payable(address(this)), amount);

        uint256 _amount0 = 0;
        uint256 _amount1 = 0;

        // check which currency to donate
        if (Currency.unwrap(poolKey.currency0) == tokenAddress) {
            _amount0 = amount;
        } else if (Currency.unwrap(poolKey.currency1) == tokenAddress) {
            _amount1 = amount;
        } else {
            // purchase token is different from pool token pair -> swap token to one of the pool tokens
            // TODO - implement handling for this case
            revert("Not handled");
        }

        bytes memory _hookData;

        delta = poolManager.donate(poolKey, _amount0, _amount1, _hookData);
    }
}
