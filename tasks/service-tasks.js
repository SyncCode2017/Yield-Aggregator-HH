// const task = require("hardhat/config")
const { updateBlocks } = require("../utils/update-blocks")

task(
    "updateBlockNumber",
    "updates to a more recent block number for use in pinning to blocks when testing on a fork of mainnet"
).setAction(async () => {
    await updateBlocks()
})
