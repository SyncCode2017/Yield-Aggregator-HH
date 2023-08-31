const { assert, expect } = require("chai")
const { network, deployments, ethers, getNamedAccounts } = require("hardhat")
const {
    developmentChains,
    networkConfig,
} = require("../helper-hardhat-config")

const { getWeth } = require("../utils/getWeth");

describe("Yield Aggregator Unit Tests", async function () {
    let yieldAggregator, yieldAggregatorConnected, wethAmountEth, wethAmountWei, amountEth, amountWei, deployer, iWeth, iWethConnected

    beforeEach(async () => {
        wethAmountEth = 50
        wethAmountWei = ethers.utils.parseEther(wethAmountEth.toString())
        amountEth = 10
        amountWei = ethers.utils.parseEther(amountEth.toString())
        deployer = (await getNamedAccounts()).deployer
        await deployments.fixture(["all", "aggregator"])
        const yieldContract = await deployments.get("YieldAggregator");
        yieldAggregator = await ethers.getContractAt(yieldContract.abi, yieldContract.address)
        iWeth = await ethers.getContractAt(
            "IWETH",
            networkConfig[network.config.chainId].WETH
        )
        await getWeth(deployer, wethAmountEth)
        const trx1 = await iWeth.approve(yieldAggregator.address, wethAmountWei, { from: deployer })
        await trx1.wait()
    })

    describe("Deposit Function", function () {
        it("allows deposit", async () => {
            const trx1 = await yieldAggregator.depositWETH(amountWei, { from: deployer })
            await trx1.wait()
            const aaveBal = Number(await yieldAggregator.getAaveWETHCurrentBalance())
            const trx2 = await yieldAggregator.updateCompoundWETHCurrentBalance()
            await trx2.wait()
            const compBal = Number(await yieldAggregator.compBalance())
            assert.equal((compBal + aaveBal), Number(amountWei))

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
    describe("Withdraw Function", function () {
        beforeEach(async () => {
            const trx = await yieldAggregator.depositWETH(amountWei, { from: deployer })
            await trx.wait()
            console.log("Deposited!")
        })
        it("allows withdrawal", async () => {
            const aaveBal = Number(await yieldAggregator.getAaveWETHCurrentBalance())
            const trx3 = await yieldAggregator.updateCompoundWETHCurrentBalance()
            await trx3.wait()
            const compBal = Number(await yieldAggregator.compBalance())
            const deployerBal = Number(await iWeth.balanceOf(deployer))
            const trx2 = await yieldAggregator.withdrawWETH({ from: deployer })
            await trx2.wait()
            const deployerBalFinal = Number(await iWeth.balanceOf(deployer))
            const aaveBalFinal = Number(await yieldAggregator.getAaveWETHCurrentBalance())
            const trx4 = await yieldAggregator.updateCompoundWETHCurrentBalance()
            await trx4.wait()
            const compBalFinal = Number(await yieldAggregator.compBalance())
            expect(compBal).to.be.greaterThanOrEqual(compBalFinal)
            expect(aaveBal).to.be.greaterThanOrEqual(aaveBalFinal)
            expect(deployerBalFinal).to.be.greaterThan(deployerBal)
        })
        it("emits FundsWithdrawn", async () => {
            await expect(yieldAggregator.withdrawWETH({ from: deployer })).to.emit(yieldAggregator, "FundsWithdrawn")
        })
    })
    describe("rebalanceWETH Function", function () {
        beforeEach(async () => {
            const trx = await yieldAggregator.depositWETH(amountWei, { from: deployer })
            await trx.wait()
            console.log("Deposited!")
        })
        it("Allows rebalancing", async () => {
            const aaveApy = (await yieldAggregator.getAaveCurrentWETHAPY()).toString()
            const compApy = (await yieldAggregator.getCompoundCurrentWETHAPY()).toString()
            const aaveBal = Number(await yieldAggregator.getAaveWETHCurrentBalance())
            const trx = await yieldAggregator.updateCompoundWETHCurrentBalance()
            await trx.wait()
            const compBal = Number(await yieldAggregator.compBalance())
            if (aaveApy > compApy && compBal > aaveBal) {
                await expect(yieldAggregator.rebalanceWETH({ from: deployer })).to.emit(yieldAggregator, "FundsMovedFromCompoundToAave")
            } else if (aaveApy < compApy && compBal < aaveBal) {
                await expect(yieldAggregator.rebalanceWETH({ from: deployer })).to.emit(yieldAggregator, "FundsMovedFromAaveToCompound")
            } else {
                await expect(yieldAggregator.rebalanceWETH({ from: deployer })).to.be.revertedWith("NoRebalanceRequired()")
            }
        })

    })
})
