// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseHook} from "v4-periphery/BaseHook.sol";

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";

import { IUnlock } from "unlock/smart-contracts/contracts/interfaces/IUnlock.sol";
import { IPublicLock } from "unlock/smart-contracts/contracts/interfaces/IPublicLock.sol";

contract MembershipHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    address public lockAddress;
    address public tokenAddress;

    uint256 public beforeSwapCount;

    constructor(IPoolManager _poolManager, IUnlock _unlock) BaseHook(_poolManager) {
        // create the lock
        uint256 _expirationDuration = 2_592_000; // 30 days
        address _tokenAddress = address(0); // address of the token to use for purchases -> 0 means ETH
        uint256 _keyPrice = 10_000_000_000_000_000; // 0.01 ETH
        uint256 _maxNumberOfKeys = 1;
        string memory _lockName = "ZeroFeeMembership";
        bytes12 _salt = bytes12(0);

        lockAddress =
            _unlock.createLock(_expirationDuration, _tokenAddress, _keyPrice, _maxNumberOfKeys, _lockName, _salt);
        tokenAddress = _tokenAddress;

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
        bool hasMembership = (IPublicLock(lockAddress).balanceOf(msg.sender) == 0);
        if (hasMembership) {
            return 0;
        }
        // 2%
        return 20000;
    }

    /// @notice Purchases a membership and returns the token ID
    function purchaseMembership(PoolKey calldata poolKey, uint256 value) external payable returns (uint256 tokenId) {
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
        
        uint256[] memory tokenIds = IPublicLock(lockAddress).purchase{ value: msg.value }(_values, _recipients, _referrers, _keyManagers, _data);

        _withdrawAndDonate(poolKey, value);

        tokenId = tokenIds[0];
    }

    /// @notice Withdraws all funds from the lock and donates them to the pool
    function _withdrawAndDonate(PoolKey calldata poolKey, uint256 amount) internal returns (BalanceDelta delta) {
        // withdraw all funds from the lock
        lockAddress.withdraw(tokenAddress, address(this), amount);

        uint256 _amount0 = 0;
        uint256 _amount1 = 0;

        // check which currency to donate
        if (poolKey.currency0 == tokenAddress) {
            _amount0 = amount;
        } else if (poolKey.currency1 == tokenAddress) {
            _amount1 = amount;
        } else {
            // purchase token is different from pool token pair -> swap token to one of the pool tokens
        }

        bytes calldata _hookData;

        delta = poolManager.donate(poolKey, amount0, amount1, _hookData);
    }
}
