#!/bin/bash
forge script script/MembershipHook.s.sol:MembershipHookScript --fork-url http://localhost:8545 --broadcast
npx hardhat run script/deployments.js
forge script script/InitializeNewPool.s.sol:InitializeNewPool --fork-url http://localhost:8545 --broadcast
forge script script/TestContracts.s.sol:TestContracts --fork-url http://localhost:8545 --broadcast
forge script script/ExecuteTransaction.s.sol:ExecuteTransaction --fork-url http://localhost:8545 --broadcast
