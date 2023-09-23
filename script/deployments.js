const { ethers, upgrades, run, unlock } = require('hardhat')

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
