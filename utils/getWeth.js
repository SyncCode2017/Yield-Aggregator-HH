const { ethers, network } = require("hardhat")
const { networkConfig } = require("../helper-hardhat-config")

const getWeth = async (account, ethValue) => {
    // const { deployer } = await getNamedAccounts()
    const iWeth = await ethers.getContractAt(
        "IWETH",
        networkConfig[network.config.chainId].WETH
    )
    console.log("iWeth", iWeth.address)
    const AMOUNT = ethers.utils.parseEther(ethValue.toString())

    const txResponse = await iWeth.deposit({
        from: account,
        value: AMOUNT,
    })
    await txResponse.wait()
    const wethBalance = await iWeth.balanceOf(account)
    console.log(`Got ${ethers.utils.formatEther(wethBalance.toString())} WETH`)
}

module.exports = { getWeth }