const { network } = require("hardhat")
const {
    networkConfig,
    developmentChains,
} = require("../helper-hardhat-config")
const { verify } = require("../utils/helper-functions")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    log("deployer", deployer)
    const chainId = network.config.chainId
    const wethAddress = networkConfig[chainId].WETH
    const cometAddress = networkConfig[chainId].comet
    const cometRewards = networkConfig[chainId].comp_rewards
    const wethCompPriceFeed = networkConfig[chainId].WETH_Comp_Price_Feed
    const aaveProtocolDataProvider =
        networkConfig[chainId].aaveProtocolDataProvider
    const aavePoolAddressesProvider =
        networkConfig[chainId].aavePoolAddressesProvider

    const argsYield = [
        wethAddress,
        cometAddress,
        cometRewards,
        wethCompPriceFeed,
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
}

module.exports.tags = ["all", "aggregator"]