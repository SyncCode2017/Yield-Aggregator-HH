//import { doesNotMatch } from "assert"
const { network } = require("hardhat")
const { resolve } = require("path")

function sleep(timeInMs) {
    console.log(`Sleeping for ${timeInMs}`)
    return new Promise((resolve) => setTimeout(resolve, timeInMs))
}
async function moveBlocks(amount) {
    console.log("Moving blocks...")
    for (let index = 0; index < amount; index++) {
        await network.provider.request({
            method: "evm_mine",
            params: [],
        })
    }
    console.log(`Moved ${amount} blocks`)
}

module.exports = { moveBlocks, sleep }