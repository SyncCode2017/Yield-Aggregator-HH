const { network } = require("hardhat")
const {
    networkConfig,
    developmentChains,
} = require("../helper-hardhat-config")
const { verify } = require("../utils/helper-functions")
const { updateFrontEnd } = require("../utils/update-front-end")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId
    const wethAddress = networkConfig[chainId].WETH
    const cometAddress = networkConfig[chainId].comet
    const cometRewards = networkConfig[chainId].comp_rewards
    const aaveProtocolDataProvider =
        networkConfig[chainId].aaveProtocolDataProvider
    const aavePoolAddressesProvider =
        networkConfig[chainId].aavePoolAddressesProvider

    const argsYield = [
        wethAddress,
        cometAddress,
        cometRewards,
        aaveProtocolDataProvider,
        aavePoolAddressesProvider,
    ]

    log("----------------------------------------------------")
    log("Deploying Yield-Aggregator and waiting for confirmations...")
    const yieldAggregator = await deploy("YieldAggregator", {
        from: deployer,
        args: argsYield,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(yieldAggregator.address, argsYield)
    }

    if (process.env.UPDATE_FRONT_END == "true") {
        updateFrontEnd()
    }
}

module.exports.tags = ["all", "aggregator"]