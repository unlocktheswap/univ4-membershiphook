const { hre, ethers, upgrades, run, unlock } = require('hardhat')

//const networkName = "customNetwork"; // Replace with the name of the network you want to use
//console.log("CONFIGS", hre.network.configs)
//const network = hre.network.configs[networkName];

async function main({ unlockVersion } = {}) {
  const [deployer] = await ethers.getSigners()
  // need to fetch previous unlock versions
  await unlock.deployProtocol();

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
