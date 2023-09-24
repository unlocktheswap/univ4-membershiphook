const { hre, ethers, upgrades, run, unlock } = require('hardhat')

//const networkName = "customNetwork"; // Replace with the name of the network you want to use
//console.log("CONFIGS", hre.network.configs)
//const network = hre.network.configs[networkName];

async function main({ unlockVersion } = {}) {
  const [deployer] = await ethers.getSigners()
  // need to fetch previous unlock versions
  await unlock.deployProtocol();

  // create a lock
  const lockArgs = {
    expirationDuration: 60 * 60 * 24 * 7, // 7 days
    currencyContractAddress: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9", // null for ETH or erc20 address
    keyPrice: "100000000", // in wei
    maxNumberOfKeys: 10,
    name: "A Demo Lock",
  };
  let lockDeployed = await unlock.createLock(lockArgs);

  await lockDeployed.lock.addLockManager('0x4899Df6EE9F016c225b97D11aB6C5b8a97035b51');


  console.log('lockDeployed', lockDeployed.lockAddress)

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
