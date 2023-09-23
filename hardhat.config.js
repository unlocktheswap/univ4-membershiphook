/** @type import('hardhat/config').HardhatUserConfig */
require("@unlock-protocol/hardhat-plugin");
module.exports = {
  solidity: "0.8.19",
  defaultNetwork: 'anvil',
  networks: {
    anvil: {
      url: "http://127.0.0.1:8545", // Replace with the URL of your specific Ethereum node
      chainId: 31337, // Replace with the chain ID of the network
      accounts: ["0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"]
    },
    // Add other network configurations if needed.
  },
  // Other configuration settings...
};