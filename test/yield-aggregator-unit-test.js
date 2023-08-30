const { assert, expect } = require("chai")
const { network, deployments, ethers, getNamedAccounts } = require("hardhat")
const {
    developmentChains,
    networkConfig,
} = require("../helper-hardhat-config")

const { getWeth } = require("../utils/getWeth");

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
        amountEth = 7
        amountWei = ethers.utils.parseEther(amountEth.toString())
        await getWeth(deployer, amountEth)
        const trx1 = await iWeth.approve(yieldAggregator.address, amountWei, { from: deployer })
        await trx1.wait()
    })

    describe("Deposit Function", function () {
        it("allows deposit", async () => {
            const aaveApy = (await yieldAggregator.getAaveCurrentWETHAPY()).toString()
            const compApy = (await yieldAggregator.getCompoundCurrentWETHAPY()).toString()
            console.log("aaveApy", aaveApy)
            console.log("compApy", compApy)
            const trx = await yieldAggregator.depositWETH(amountWei, { from: deployer })
            await trx.wait()
            console.log("Deposited!")
            const aaveBal = Number(await yieldAggregator.getAaveWETHCurrentBalance())
            const trx3 = await yieldAggregator.updateCompoundWETHCurrentBalance()
            await trx3.wait()
            const compBal = Number(await yieldAggregator.compBalance())
            const contractBal = (await iWeth.balanceOf(yieldAggregator.address)).toString()
            const deployerBal = (await iWeth.balanceOf(deployer)).toString()
            console.log("aaveBal", aaveBal)
            console.log("compBal", compBal)
            console.log("contractBal", contractBal)
            console.log("deployerBal", deployerBal)
            const trx2 = await yieldAggregator.withdrawWETH({ from: deployer })
            await trx2.wait()
            console.log("Withdrawn!")
            const contractBalFinal = (await iWeth.balanceOf(yieldAggregator.address)).toString()
            const deployerBalFinal = (await iWeth.balanceOf(deployer)).toString()
            const aaveBalFinal = (await yieldAggregator.getAaveWETHCurrentBalance()).toString()
            const trx4 = await yieldAggregator.updateCompoundWETHCurrentBalance()
            await trx4.wait()
            //const compBal = await yieldAggregator.compBalance()
            const compBalFinal = Number(await yieldAggregator.compBalance())
            console.log("aaveBalFinal", aaveBalFinal)
            console.log("compBalFinal", compBalFinal)
            console.log("contractBalFinal", contractBalFinal)
            console.log("deployerBalFinal", deployerBalFinal)
            assert.equal(((compBal) + (aaveBal)), Number(amountWei))

        })
        it("emits FundsDepositedToAave / FundsDepositedToCompound", async () => {
            const aaveApy = Number(await yieldAggregator.getAaveCurrentWETHAPY())
            const compApy = Number(await yieldAggregator.getCompoundCurrentWETHAPY())
            if (aaveApy >= compApy) {
                await expect(yieldAggregator.depositWETH(amountWei, { from: deployer })).to.emit(yieldAggregator, "FundsDepositedToAave")
            } else {
                await expect(yieldAggregator.depositWETH(amountWei, { from: deployer })).to.emit(yieldAggregator, "FundsDepositedToCompound")
            }
        })

    })
})