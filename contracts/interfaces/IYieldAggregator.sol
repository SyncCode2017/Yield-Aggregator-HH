// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IYieldAggregator {
    error ApproveRightAmount();
    error InsufficientBalance();
    error NoAaveRewardsClaimed();
    error DepositToAaveFailed();
    error AaveWithdrawalFailed();
    error DepositToCompoundFailed();
    error CompoundWithdawalFailed();
    error ClaimRewardsFromCompoundFailed();
    error ClaimAaveRewardsFailed();
    error NoRebalanceRequired();

    /// @dev Emitted when funds are withdrawn by the user
    event FundsWithdrawn(address _owner, uint256 _amount);
    /// @dev Emitted when funds are deposited
    event FundsDepositedToAave(uint256 _amount);
    /// @dev Emitted when funds are withdrawn from Aave
    event FundsWithdrawnFromAave(uint256 _amount);
    /// @dev Emitted when funds are deposited to Compound
    event FundsDepositedToCompound(uint256 _amount);
    /// @dev Emitted when funds are withdrawn from Compound
    event FundsWithdrawnFromCompound(uint256 _amount);
    /// @dev Emitted when funds are rebalanced from Aave to Compound
    event FundsMovedFromAaveToCompound(uint256 _amount);
    /// @dev Emitted when funds are rebalanced from Compound to Aave
    event FundsMovedFromCompoundToAave(uint256 _amount);

    /// @notice Allow the owner to deposit to Aave and Compound
    /// @dev only accepts WETH token
    /// @param _amount in wei to be deposited
    function depositWETH(uint256 _amount) external;

    /// @notice Allows the owner to withraw his asset from Aave or Compound
    function withdrawWETH() external;

    /// @notice Allows the caller to move the asset the protocol with higher apy
    function rebalanceWETH() external;

    /// @notice Claims the reward tokens due to this contract address
    function claimCompRewards() external;

    /// @dev Returns current contract balance in Compound
    function getCompoundWETHCurrentBalance() external view returns (uint256);

    /// @dev Returns Aave APY
    function getAaveCurrentWETHAPY() external view returns (uint256);

    /// @dev Returns Compound APY
    function getCompoundCurrentWETHAPY() external view returns (uint256);

    /// @dev Returns current contract balance in Aave
    function getAaveWETHCurrentBalance() external view returns (uint256);

    /// @notice Get the current price of an asset from the protocol's persepctive
    function getCompoundPrice(address singleAssetPriceFeed) external view returns (uint256);
}
