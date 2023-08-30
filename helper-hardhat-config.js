const networkConfig = {
    31337: {
        name: "localhost",
        comet: "0xc3d688B66703497DAA19211EEdff47f25384cdc3",
        comp_rewards: "0x1B0e765F6224C21223AeA2af16c1C46E38885a40",
        WETH: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
        WETH_Comp_Price_Feed: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419",
        aaveProtocolDataProvider: "0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3",
        aavePoolAddressesProvider: "0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e",
        WETHAToken: "0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8",
    },
    31337: {
        name: "hardhat",
        comet: "0xc3d688B66703497DAA19211EEdff47f25384cdc3",
        comp_rewards: "0x1B0e765F6224C21223AeA2af16c1C46E38885a40",
        WETH: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
        WETH_Comp_Price_Feed: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419",
        aaveProtocolDataProvider: "0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3",
        aavePoolAddressesProvider: "0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e",
        WETHAToken: "0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8",
    },

    1: {
        name: "mainnet",
        comet: "0xc3d688B66703497DAA19211EEdff47f25384cdc3",
        comp_rewards: "0x1B0e765F6224C21223AeA2af16c1C46E38885a40",
        WETH: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        WETH_Comp_Price_Feed: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419",
        aaveProtocolDataProvider: "0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3",
        aavePoolAddressesProvider: "0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e",
        WETHAToken: "0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8",
    },

    //   4: {
    //     name: "rinkeby",
    //     eth_address: "0x11D634457F99595aBE7B582739fd52b7ed48995A",
    //   },
    //   42: {
    //     name: "kovan",
    //     eth_address: "0x806a8543F1b28b3623078AD66551102485a84A8F",
    //   },
};

const developmentChains = ["hardhat", "localhost"];

module.exports = {
    networkConfig,
    developmentChains,
};