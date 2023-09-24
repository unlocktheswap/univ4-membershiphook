// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/console2.sol";
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

    // TODO - need to refactor so we use pool keys inside of functions
    // and can support more pools
    PoolKey public poolKey;
    // Address of our account abstraction contract which will be
    // the usual entry point into interacting with the pool
    address public aaAddr;

    // Interfaces for the Unlock NFT contract
    mapping(PoolId => IPublicLock) public flatRateLockContracts;
    mapping(PoolId => IPublicLock) public mevProtectionLockContracts;
    // Address of the erc20s that has to be used to pay for membership
    mapping(PoolId => address) public tokenAddresses;
    mapping(address => uint) public lastSwap;

    struct CallbackData {
        address sender;
        PoolKey key;
        uint256 amount0;
        uint256 amount1;
    }

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return
            Hooks.Calls({
                beforeInitialize: false,
                afterInitialize: true,
                beforeModifyPosition: false,
                afterModifyPosition: false,
                beforeSwap: true,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false
            });
    }

    /// @notice From chat-gpt, needed as we will always pass in an address with our initiialization data
    function _bytesToAddress(bytes memory bys) internal pure returns (address) {
        require(bys.length == 20, "Invalid address length"); // Check that the input bytes are 20 bytes long (160 bits)
        address addr;
        assembly {
            addr := mload(add(bys, 0x14)) // Load the 20 bytes from memory and store it as an address
        }
        return addr;
    }

    /// @notice We need the address of the account abstraction address
    /// TODO - Need modifiers to prevent anyone from calling this!
    function setAAAddr(address _aaAddr) external {
        aaAddr = _aaAddr;
    }

    function afterInitialize(
        address,
        PoolKey calldata key,
        uint160,
        int24,
        bytes calldata _data
    ) external override poolManagerOnly returns (bytes4) {
        // _data will be two addresses!
        poolKey = key;
        address _flatRateLock = _bytesToAddress(_data[0:20]);
        address _mevProtectionLock = _bytesToAddress(_data[20:40]);
        console2.log("afterInitialize addresses");
        console2.log(_flatRateLock);
        console2.log(_mevProtectionLock);

        IPublicLock flatRateLockContract = IPublicLock(_flatRateLock);
        IPublicLock mevProtectionLockContract = IPublicLock(_mevProtectionLock);

        // Payment token associated with the lockContract
        address tokenAddress = flatRateLockContract.tokenAddress();

        uint tempbal = flatRateLockContract.balanceOf(address(this));
        console2.log("tempbal ok");

        PoolId poolNum = poolKey.toId();

        // Add them to map
        flatRateLockContracts[poolNum] = flatRateLockContract;
        mevProtectionLockContracts[poolNum] = mevProtectionLockContract;

        tokenAddresses[poolNum] = tokenAddress;

        return BaseHook.afterInitialize.selector;
    }

    function _inferUser(
        address sender,
        bytes calldata data
    ) internal view returns (address user) {
        if (sender == aaAddr) {
            user = _bytesToAddress(data);
        } else {
            user = sender;
        }
    }

    function beforeSwap(
        address sender,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        bytes calldata data
    ) external override returns (bytes4) {
        console2.log("beforeSwap called");
        address user = _inferUser(sender, data);
        console2.log("got user");
        // Sandwich attack protection: only allow one swap per block
        // unless they have the special MEV NFT
        if (lastSwap[user] == block.number) {
            console2.log("match");
            PoolId poolNum = poolKey.toId();
            IPublicLock mevProtectionLockContract = flatRateLockContracts[
                poolNum
            ];
            console2.log("hasMembership");
            bool hasMembership = mevProtectionLockContract.balanceOf(user) > 0;
            if (!hasMembership) {
                revert("Only one swap per block");
            }
        }
        console2.log("no match");
        lastSwap[user] = block.number;
        console2.log("set value, done");
        return BaseHook.beforeSwap.selector;
    }

    /// @notice Returns the dynamic fee that we'll charge on swaps: free for members, 2% for others
    function getFee(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata data
    ) external returns (uint24 newFee) {
        console2.log("getFee called");
        //PoolId poolNum = key.toId();
        PoolId poolNum = poolKey.toId();
        console2.log("getFee 1");
        IPublicLock flatRateLockContract = flatRateLockContracts[poolNum];
        console2.log("getFee 2");
        address user = _inferUser(sender, data);
        console2.log("getFee 3");
        console2.log("USER IS", user);
        bool hasMembership = flatRateLockContract.balanceOf(user) > 0;
        console2.log("getFee 4");
        if (hasMembership) {
            return 0;
        }
        // 2%
        return 20000;
    }

    /// @notice Purchases a membership and returns the token ID
    function purchaseMembership(
        PoolKey calldata key,
        uint256 value,
        address purchaser
    ) external payable returns (uint256 tokenId) {
        // parameters for key purchase
        uint256[] memory _values = new uint256[](1);
        _values[0] = value;

        address[] memory _recipients = new address[](1);
        _recipients[0] = purchaser;

        address[] memory _referrers = new address[](1);
        _referrers[0] = msg.sender;

        address[] memory _keyManagers = new address[](1);
        _keyManagers[0] = msg.sender;

        bytes[] memory _data = new bytes[](1);
        _data[0] = bytes("0x");

        //PoolId poolNum = key.toId();
        PoolId poolNum = poolKey.toId();
        IPublicLock flatRateLockContract = flatRateLockContracts[poolNum];
        uint256[] memory tokenIds = flatRateLockContract.purchase(
            _values,
            _recipients,
            _referrers,
            _keyManagers,
            _data
        );

        // _withdrawAndDonate(value, poolNum);

        tokenId = tokenIds[0];
    }

    /// @notice Withdraws all funds from the lock and donates them to the pool
    function _withdrawAndDonate(
        uint256 amount,
        PoolId poolNum
    ) internal returns (BalanceDelta delta) {
        // withdraw all funds from the lock

        address tokenAddress = tokenAddresses[poolNum];
        IPublicLock flatRateLockContract = flatRateLockContracts[poolNum];

        flatRateLockContract.withdraw(
            tokenAddress,
            payable(address(this)),
            amount
        );

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

        // Fails because we need lock
        delta = poolManager.donate(poolKey, _amount0, _amount1, _hookData);

        // Need to obtain lock to call donate
        // Need a reference to manager...
        // delta = abi.decode(
        //     manager.lock(
        //         abi.encode(CallbackData(poolKey, _amount0, _amount1, _hookData))
        //     ),
        //     (BalanceDelta)
        // );
    }
}
