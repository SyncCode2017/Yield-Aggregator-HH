const fs = require("fs")
require("dotenv").config()

const updateBlocks = async () => {
    const dataFromFile = fs.readFileSync("./utils/config.json")
    let blockData

    try {
        blockData = JSON.parse(dataFromFile.toString())
    } catch (err) {
        console.log(
            "There was an error parsing blockNumber JSON data from file. Requesting new block..."
        )
    } finally {
        // Get current timestamp
        const currentTimestamp = Math.round(new Date().getTime() / 1000)

        // If last block update is more than 3 days ago (or if error in reading from file), update block number
        if (
            currentTimestamp - (blockData?.lastUpdated ? blockData.lastUpdated : 0) >
            3600 * 24 * 3
        ) {
            const ALCHEMY_MAINNET_KEY = process.env.ALCHEMY_MAINNET_KEY
            const provider = new ethers.providers.AlchemyProvider(
                "homestead",
                ALCHEMY_MAINNET_KEY
            )
            const newBlockNumber = await provider.getBlockNumber()

            // Save new data to file
            blockData = {
                blockNumber: newBlockNumber,
                lastUpdated: currentTimestamp,
            }
            const dataToWrite = JSON.stringify(blockData)

            fs.writeFileSync("./utils/config.json", dataToWrite)
        }
    }

    return blockData.blockNumber
}

module.exports = { updateBlocks }