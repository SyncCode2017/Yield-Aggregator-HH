# CometStructs
[Git Source](https://github.com/SyncCode2017/yield-aggregator-hh/blob/b0c4faacf958598cfd8e723937511d7ce489672f/contracts/interfaces/IComet.sol)


## Structs
### AssetInfo

```solidity
struct AssetInfo {
    uint8 offset;
    address asset;
    address priceFeed;
    uint64 scale;
    uint64 borrowCollateralFactor;
    uint64 liquidateCollateralFactor;
    uint64 liquidationFactor;
    uint128 supplyCap;
}
```

### UserBasic

```solidity
struct UserBasic {
    int104 principal;
    uint64 baseTrackingIndex;
    uint64 baseTrackingAccrued;
    uint16 assetsIn;
    uint8 _reserved;
}
```

### TotalsBasic

```solidity
struct TotalsBasic {
    uint64 baseSupplyIndex;
    uint64 baseBorrowIndex;
    uint64 trackingSupplyIndex;
    uint64 trackingBorrowIndex;
    uint104 totalSupplyBase;
    uint104 totalBorrowBase;
    uint40 lastAccrualTime;
    uint8 pauseFlags;
}
```

### UserCollateral

```solidity
struct UserCollateral {
    uint128 balance;
    uint128 _reserved;
}
```

### RewardOwed

```solidity
struct RewardOwed {
    address token;
    uint256 owed;
}
```

### TotalsCollateral

```solidity
struct TotalsCollateral {
    uint128 totalSupplyAsset;
    uint128 _reserved;
}
```

