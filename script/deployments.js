const { unlock } = require("hardhat");

async function deployUnlockAndCreateLock() {
  
    try {
      // deploy the Unlock contract
      await unlock.deployUnlock();
  
      // deploy the template
      await unlock.deployPublicLock();
  
      // deploy the entire protocol (localhost only)
      await unlock.deployProtocol();
  
      // create a lock
      const lockArgs = {
        expirationDuration: 60 * 60 * 24 * 7, // 7 days
        currencyContractAddress: null, // null for ETH or erc20 address
        keyPrice: "100000000", // in wei
        maxNumberOfKeys: 1,
        name: "A Demo Lock",
      };
      await unlock.createLock(lockArgs);
  
      console.log("Unlock and Lock deployment completed successfully.");
    } catch (error) {
      console.error("Error deploying Unlock and Lock:", error);
    }
  }
  
module.exports = deployUnlockAndCreateLock;
  