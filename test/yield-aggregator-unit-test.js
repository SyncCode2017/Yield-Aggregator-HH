const { assert, expect } = require("chai")
const { network, deployments, ethers, getNamedAccounts } = require("hardhat")
const {
    developmentChains,
    networkConfig,
} = require("../helper-hardhat-config")

const { getWeth } = require("../utils/getWeth")
const { moveTime } = require("../utils/move-time")

describe("Yield Aggregator Unit Tests", async function () {
    let yieldAggregator, wethAmountEth, wethAmountWei, amountEth, amountWei, deployer, iWeth, alice, accounts

    beforeEach(async () => {
        wethAmountEth = 50
        wethAmountWei = ethers.utils.parseEther(wethAmountEth.toString())
        amountEth = 10
        amountWei = ethers.utils.parseEther(amountEth.toString())
        deployer = (await getNamedAccounts()).deployer
        accounts = await ethers.getSigners()
        alice = accounts[1]
        await deployments.fixture(["all", "aggregator"])
        const yieldContract = await deployments.get("YieldAggregator")
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
        it("allows deposit from owner", async () => {
            const trx1 = await yieldAggregator.depositWETH(amountWei, { from: deployer })
            await trx1.wait()
            const aaveBal = Number(await yieldAggregator.getAaveWETHCurrentBalance())
            const compBal = Number(await yieldAggregator.getCompoundWETHCurrentBalance())
            assert.equal((compBal + aaveBal), Number(amountWei))

        })
        it("rejects deposit from a random account", async () => {
            await expect(yieldAggregator.connect(alice).depositWETH(amountWei)).to.be.revertedWith("Ownable")
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
        it("does not receive ether", async () => {
            await expect(alice.sendTransaction({ to: yieldAggregator.address, value: amountWei })).to.be.reverted
        })
    })
    describe("Withdraw Function", function () {
        beforeEach(async () => {
            const trx = await yieldAggregator.depositWETH(amountWei, { from: deployer })
            await trx.wait()
            console.log("Deposited!")
        })
        it("allows withdrawal", async () => {
            await moveTime(100000)
            const aaveBal = Number(await yieldAggregator.getAaveWETHCurrentBalance())
            const compBal = Number(await yieldAggregator.getCompoundWETHCurrentBalance())
            const deployerBal = Number(await iWeth.balanceOf(deployer))
            const trx2 = await yieldAggregator.withdrawWETH({ from: deployer })
            await trx2.wait()
            const deployerBalFinal = Number(await iWeth.balanceOf(deployer))
            const aaveBalFinal = Number(await yieldAggregator.getAaveWETHCurrentBalance())
            const compBalFinal = Number(await yieldAggregator.getCompoundWETHCurrentBalance())
            expect(compBal).to.be.greaterThanOrEqual(compBalFinal)
            expect(aaveBal).to.be.greaterThanOrEqual(aaveBalFinal)
            expect(deployerBalFinal).to.be.greaterThan(deployerBal)

        })
        it("rejects withdrawal by a random account", async () => {
            await expect(yieldAggregator.connect(alice).withdrawWETH()).to.be.revertedWith("Ownable")
        })
        it("emits FundsWithdrawn", async () => {
            await moveTime(100000)
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
            await moveTime(100000)
            const aaveApy = Number(await yieldAggregator.getAaveCurrentWETHAPY())
            const compApy = Number(await yieldAggregator.getCompoundCurrentWETHAPY())
            const aaveBal = Number(await yieldAggregator.getAaveWETHCurrentBalance())
            const compBal = Number(await yieldAggregator.getCompoundWETHCurrentBalance())
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
