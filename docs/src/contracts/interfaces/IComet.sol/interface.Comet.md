# Comet
[Git Source](https://github.com/SyncCode2017/yield-aggregator-hh/blob/9547b64ff0dde35cf66a54081393a0499b5c1eda/contracts/interfaces/IComet.sol)


## Functions
### baseScale


```solidity
function baseScale() external view returns (uint256);
```

### supply


```solidity
function supply(address asset, uint256 amount) external;
```

### withdraw


```solidity
function withdraw(address asset, uint256 amount) external;
```

### getSupplyRate


```solidity
function getSupplyRate(uint256 utilization) external view returns (uint256);
```

### getBorrowRate


```solidity
function getBorrowRate(uint256 utilization) external view returns (uint256);
```

### getAssetInfoByAddress


```solidity
function getAssetInfoByAddress(address asset) external view returns (CometStructs.AssetInfo memory);
```

### getAssetInfo


```solidity
function getAssetInfo(uint8 i) external view returns (CometStructs.AssetInfo memory);
```

### getPrice


```solidity
function getPrice(address priceFeed) external view returns (uint128);
```

### userBasic


```solidity
function userBasic(address) external view returns (CometStructs.UserBasic memory);
```

### totalsBasic


```solidity
function totalsBasic() external view returns (CometStructs.TotalsBasic memory);
```

### userCollateral


```solidity
function userCollateral(address, address) external view returns (CometStructs.UserCollateral memory);
```

### baseTokenPriceFeed


```solidity
function baseTokenPriceFeed() external view returns (address);
```

### numAssets


```solidity
function numAssets() external view returns (uint8);
```

### getUtilization


```solidity
function getUtilization() external view returns (uint256);
```

### baseTrackingSupplySpeed


```solidity
function baseTrackingSupplySpeed() external view returns (uint256);
```

### baseTrackingBorrowSpeed


```solidity
function baseTrackingBorrowSpeed() external view returns (uint256);
```

### totalSupply


```solidity
function totalSupply() external view returns (uint256);
```

### totalBorrow


```solidity
function totalBorrow() external view returns (uint256);
```

### baseIndexScale


```solidity
function baseIndexScale() external pure returns (uint64);
```

### totalsCollateral


```solidity
function totalsCollateral(address asset) external view returns (CometStructs.TotalsCollateral memory);
```

### baseMinForRewards


```solidity
function baseMinForRewards() external view returns (uint256);
```

### baseToken


```solidity
function baseToken() external view returns (address);
```

