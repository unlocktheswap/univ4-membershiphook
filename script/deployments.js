const { hre, ethers, upgrades, run, unlock } = require('hardhat')

//const networkName = "customNetwork"; // Replace with the name of the network you want to use
//console.log("CONFIGS", hre.network.configs)
//const network = hre.network.configs[networkName];

async function main({ unlockVersion } = {}) {
  const [deployer] = await ethers.getSigners()
  // need to fetch previous unlock versions
  await unlock.deployProtocol();

  // create a lock
  const lockArgs1 = {
    expirationDuration: 60 * 60 * 24 * 7, // 7 days
    currencyContractAddress: null, // "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9", // null for ETH or erc20 address
    keyPrice: "0", // in wei
    maxNumberOfKeys: 1000,
    name: "FlatRateSubscription",
  };
  let lock1Deployed = await unlock.createLock(lockArgs1);

  await lock1Deployed.lock.addLockManager('0x48488B1B7A89fc75D0889fa6d1065D0c4FDB6C6a');

  console.log('lock1Deployed', lock1Deployed.lockAddress);

  // create a lock
  const lockArgs2 = {
    expirationDuration: 60 * 60 * 24 * 7, // 7 days
    currencyContractAddress: null, // "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9", // null for ETH or erc20 address
    keyPrice: "0", // in wei
    maxNumberOfKeys: 2,
    name: "FlatRateSubscription",
  };
  let lock2Deployed = await unlock.createLock(lockArgs2);

  await lock2Deployed.lock.addLockManager('0x48488B1B7A89fc75D0889fa6d1065D0c4FDB6C6a');

  console.log('lock2Deployed', lock2Deployed.lockAddress);

  return unlock.address
}

// execute as standalone
if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error)
      process.exit(1)
    })
}

module.exports = main
