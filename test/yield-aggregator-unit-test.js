const { assert, expect } = require("chai")
const { network, deployments, ethers, getNamedAccounts } = require("hardhat")
const {
    developmentChains,
    networkConfig,
} = require("../helper-hardhat-config")

const { getWeth } = require("../utils/getWeth");
// const pricePerUnit = ethers.utils.parseEther("10")
// const quantity = 10
// const allowedItemsArray = [
//     "orange",
//     "bread",
//     "mango",
//     "bannana",
//     "beans",
//     "rice",
//     "32in-bone-straight-wig",
// ]
// const invalidItem = "blue"

describe("Yield Aggregator Unit Tests", async function () {
    let yieldAggregator, yieldAggregatorConnected, amountEth, amountWei, deployer, iWeth, iWethConnected

    beforeEach(async () => {
        deployer = (await getNamedAccounts()).deployer

        // accounts = await ethers.getSigners()
        // deployer = accounts[0]
        // userSell = accounts[1]
        // userBuy = accounts[2]
        await deployments.fixture(["all", "aggregator"])
        const yieldContract = await deployments.get("YieldAggregator");
        yieldAggregator = await ethers.getContractAt(yieldContract.abi, yieldContract.address)
        // yieldAggregatorConnected = await yieldAggregator.connect(deployer)
        iWeth = await ethers.getContractAt(
            "IWETH",
            networkConfig[network.config.chainId].WETH
        );
        // iWethConnected = await iWeth.connect(deployer)
        amountEth = 10
        amountWei = ethers.utils.parseEther(amountEth.toString())
        await getWeth(deployer, amountEth)
        // marketplaceSeller = await marketplace.connect(userSell)
        // marketplaceBuyer = await marketplace.connect(userBuy)
    })

    describe("Deposit Function", function () {
        it("allows deposit", async () => {
            const trx1 = await iWeth.approve(yieldAggregator.address, amountWei, { from: deployer })
            await trx1.wait()
            const trx = await yieldAggregator.depositWETH(amountWei, { from: deployer })
            await trx.wait()
            const aaveBal = (await yieldAggregator.getAaveWETHCurrentBalance()).toString()
            const compBal = ((await yieldAggregator.getCompoundWETHCurrentBalance()).value).toString()
            const contractBal = (await iWeth.balanceOf(yieldAggregator.address)).toString()
            const deployerBal = (await iWeth.balanceOf(deployer)).toString()
            console.log("aaveBal", aaveBal)
            console.log("compBal", compBal)
            console.log("contractBal", contractBal)
            console.log("deployerBal", deployerBal)
            const trx2 = await yieldAggregator.withdrawWETH({ from: deployer })
            await trx2.wait()
            console.log("aaveBal", aaveBal)
            console.log("compBal", compBal)
            console.log("contractBal", contractBal)
            console.log("deployerBal", deployerBal)
            assert.equal((Number(compBal) + Number(aaveBal)), Number(amountWei))

        })
    })
})