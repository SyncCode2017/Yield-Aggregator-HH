
const fs = require("fs")
const { network, deployments } = require("hardhat")
const { frontEndContractsFile, frontEndAbiLocation } = require("../helper-hardhat-config")

const updateFrontEnd = async () => {
  console.log("Writing to front end...")
  await updateContractAddresses()
  await updateAbi()
  console.log("Front end written!")

}

async function updateAbi() {
  // Get YieldAggregator contract
  const yieldAggregator = await deployments.get("YieldAggregator")
  const abi = yieldAggregator.abi
  fs.writeFileSync(`${frontEndAbiLocation}YieldAggregator.json`, JSON.stringify(abi))
}

async function updateContractAddresses() {
  const chainId = network.config.chainId.toString()
  // Get YieldAggregator contract
  const yieldAggregator = await deployments.get("YieldAggregator")
  const yieldAggregatorAddress = JSON.parse(
    fs.readFileSync(frontEndContractsFile, "utf8")
  )
  if (chainId in yieldAggregatorAddress) {
    if (!yieldAggregatorAddress[chainId]["YieldAggregator"].includes(yieldAggregator.address)) {
      yieldAggregatorAddress[chainId]["YieldAggregator"].unshift(yieldAggregator.address)
    }
  } else {
    yieldAggregatorAddress[chainId] = { YieldAggregator: [yieldAggregator.address] }
  }
  fs.writeFileSync(frontEndContractsFile, JSON.stringify(yieldAggregatorAddress))
}
module.exports = { updateFrontEnd }

