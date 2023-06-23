// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";
import "@aave/core-v3/contracts/interfaces/IPoolDataProvider.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/periphery-v3/contracts/rewards/interfaces/IRewardsController.sol";
import {Comet} from "./interfaces/IComet.sol";
import {CometRewards} from "./interfaces/IComet.sol";
import {CometStructs} from "./interfaces/IComet.sol";

error ApproveRightAmount();
error InsufficientBalance();
error NoAaveRewardsClaimed();

/** @title A yield aggregator contract for optimising users APY in Aave and
 * COMPOUND.
 *  @author Abolaji
 *  @dev It monitors APY in both Aave and COMPOUND
 */

contract YieldAggregator is ReentrancyGuard, Ownable {
    // defensive as not required after pragma ^0.8
    using SafeMath for uint256;
    using ERC165Checker for address;
    using SafeERC20 for IERC20;
    address public immutable WETH_ADDRESS;
    address public immutable compAddress;
    address public immutable compRewardAddress;
    Comet public immutable COMPOUND;
    address public wethCompPriceFeed;
    uint public constant DAYS_PER_YEAR = 365;
    uint public constant SECONDS_PER_DAY = 60 * 60 * 24;
    uint public constant RAY = 10 ** 27;
    uint public constant SECONDS_PER_YEAR = SECONDS_PER_DAY * DAYS_PER_YEAR;
    uint public BASE_MANTISSA;
    uint public BASE_INDEX_SCALE;
    uint public constant MAX_UINT = type(uint).max;
    IRewardsController public aaveRewardsContract;

    IPoolAddressesProvider public immutable LENDING_POOL_ADDRESSES_PROVIDER;

    IPoolDataProvider public immutable aaveDataProvider;
    IPool public aaveLendingPool;

    //Events
    event FundsWithdrawn(address _owner, uint256 _amount, uint256 _time);
    event FundsDepositedToAave(uint256 _amount, uint256 _time);
    event FundsWithdrawnFromAave(uint256 _amount, uint256 _time);
    event FundsDepositedToCompound(uint256 _amount, uint256 _time);
    event FundsWithdrawnFromCompound(uint256 _amount, uint256 _time);

    constructor(address _wethAddress, address _cometAddress, address _cometRewardAddress, address _wethCompPriceFeed, address _aaveProtocolDataProvider, address _aavePoolAddressesProvider) {
        // initialise the contract
        WETH_ADDRESS = _wethAddress;
        aaveDataProvider = IPoolDataProvider(_aaveProtocolDataProvider);
        LENDING_POOL_ADDRESSES_PROVIDER = IPoolAddressesProvider(_aavePoolAddressesProvider);
        aaveLendingPool = IPool(LENDING_POOL_ADDRESSES_PROVIDER.getPool());
        compAddress = _cometAddress;
        compRewardAddress = _cometRewardAddress;
        COMPOUND = Comet(compAddress);
        wethCompPriceFeed = _wethCompPriceFeed;
        BASE_MANTISSA = COMPOUND.baseScale();
        BASE_INDEX_SCALE = COMPOUND.baseIndexScale();
    }

    /// @notice Contribute fund on behalf of another address for the open campaign.
    /// @dev only accepts ERC-20 deposit when campaign is open
    /// @param _amount in wei to be deposited
    function depositWETH(uint256 _amount) external nonReentrant onlyOwner {
        _recieveWETH(msg.sender, _amount);
        // compare the apy of aave and COMPOUND
        // deposit to the one with the highest APY
        if (getAaveCurrentWETHAPY() >= getCompoundCurrentWETHAPY()) {
            _depositWETHToAave(_amount);
        } else {
            _depositWETHToCompound(_amount);
        }
    }

    /// @notice Funds are released to the authorised business wallet based on the
    /// milestone schedule.
    /// @dev Only the authorised business wallet can withdraw
    function withdrawWETH() external nonReentrant onlyOwner {
        _withdrawWETHFromAave();
        _withdrawWETHFromCompound();
        uint256 _contractBalance = IERC20(WETH_ADDRESS).balanceOf(address(this));
        if (_contractBalance <= 0) revert InsufficientBalance();
        _sendWETH(owner(), _contractBalance);
        emit FundsWithdrawn(owner(), _contractBalance, block.timestamp);
    }

    function rebalanceWETH() external {
        uint256 _wethBalanceAave = getAaveWETHCurrentBalance();
        uint256 _wethBalanceCompound = getCompoundWETHCurrentBalance();

        if (getAaveCurrentWETHAPY() > getCompoundCurrentWETHAPY() && _wethBalanceCompound > _wethBalanceAave) {
            _withdrawWETHFromCompound();
            uint256 _contractBalance = IERC20(WETH_ADDRESS).balanceOf(address(this));
            _depositWETHToAave(_contractBalance);
        } else if (getAaveCurrentWETHAPY() < getCompoundCurrentWETHAPY() && _wethBalanceCompound < _wethBalanceAave) {
            _withdrawWETHFromAave();
            uint256 _contractBalance = IERC20(WETH_ADDRESS).balanceOf(address(this));
            _depositWETHToCompound(_contractBalance);
        }
    }

    /// @dev returns Aave APY
    function getAaveCurrentWETHAPY() public view returns (uint256) {
        DataTypes.ReserveData memory reserveData = aaveLendingPool.getReserveData(WETH_ADDRESS);
        uint128 currentLiquidityRate = reserveData.currentLiquidityRate;
        uint256 _depositAPR = currentLiquidityRate / RAY;
        uint256 depositAPY = ((1 + (_depositAPR.div(SECONDS_PER_YEAR))) ** SECONDS_PER_YEAR).sub(1);

        return depositAPY;
    }

    /*
     * Get the current reward for supplying APR in Compound III
     * @param rewardTokenPriceFeed The address of the reward token (e.g. COMP) price feed
     * @return The reward APR in USD as a decimal scaled up by 1e18
     */
    function getCompoundCurrentWETHAPY() public view returns (uint256) {
        uint rewardTokenPriceInUsd = getCompoundPrice(wethCompPriceFeed);
        uint usdcPriceInUsd = getCompoundPrice(COMPOUND.baseTokenPriceFeed());
        uint usdcTotalSupply = COMPOUND.totalSupply();
        uint baseTrackingSupplySpeed = COMPOUND.baseTrackingSupplySpeed();
        uint rewardToSuppliersPerDay = baseTrackingSupplySpeed * SECONDS_PER_DAY * (BASE_INDEX_SCALE / BASE_MANTISSA);
        uint supplyBaseRewardApr = ((rewardTokenPriceInUsd * rewardToSuppliersPerDay) / (usdcTotalSupply * usdcPriceInUsd)) * DAYS_PER_YEAR;
        return supplyBaseRewardApr;
    }

    /// @dev returns current contract balance in Compund
    function getCompoundWETHCurrentBalance() public returns (uint256) {
        return (COMPOUND.userCollateral(address(this), WETH_ADDRESS).balance + getCompUnclaimedRewards());
    }

    /// @dev returns current contract balance in Aave
    function getAaveWETHCurrentBalance() public view returns (uint256) {
        (uint256 totalCollateralBase, , , , , ) = aaveLendingPool.getUserAccountData(address(this));
        return totalCollateralBase;
    }

    /// @dev contract cannot receive ether
    receive() external payable {
        revert();
    }

    /// @notice Transfer Weth from a sender to the contract
    /// @param _from The recipient address
    /// @param _amount The amount of tokens to transfer from the sender
    function _recieveWETH(address _from, uint256 _amount) internal {
        // check how much the sender has approved for this transaction
        if (IERC20(WETH_ADDRESS).allowance(_from, address(this)) < _amount) revert ApproveRightAmount();
        // receive deposit and update state
        IERC20(WETH_ADDRESS).safeTransferFrom(_from, address(this), _amount);
    }

    /// @notice Transfer Weth from the contract to the recipient
    /// @param _to The recipient address
    /// @param _amount The amount of tokens to transfer
    function _sendWETH(address _to, uint256 _amount) internal {
        address payable _recipient = payable(_to);
        // send token to the recipient
        IERC20(WETH_ADDRESS).safeTransfer(_recipient, _amount);
    }

    function _depositWETHToAave(uint256 _amount) internal {
        IERC20(WETH_ADDRESS).approve(address(aaveLendingPool), _amount);
        aaveLendingPool.deposit(WETH_ADDRESS, _amount, address(this), 0);
        emit FundsDepositedToAave(_amount, block.timestamp);
    }

    function _withdrawWETHFromAave() internal {
        uint256 _collateralAmount = getAaveWETHCurrentBalance();
        uint256 _rewardsAmount = getAaveUnclaimedRewards();
        if (_rewardsAmount > 0) {
            claimAaveRewards();
        }
        if (_collateralAmount > 0) {
            aaveLendingPool.withdraw(WETH_ADDRESS, _collateralAmount, address(this));
            emit FundsWithdrawnFromAave(_collateralAmount.add(_rewardsAmount), block.timestamp);
        }
    }

    function _depositWETHToCompound(uint256 _amount) internal {
        IERC20(WETH_ADDRESS).approve(address(COMPOUND), _amount);
        COMPOUND.supply(WETH_ADDRESS, _amount);
        emit FundsDepositedToCompound(_amount, block.timestamp);
    }

    function _withdrawWETHFromCompound() internal {
        uint256 _collateralAmount = getCompoundWETHCurrentBalance();
        uint256 _rewardsAmount = getCompUnclaimedRewards();
        if (_rewardsAmount > 0) {
            claimCompRewards();
        }
        if (_collateralAmount > 0) {
            COMPOUND.withdraw(WETH_ADDRESS, _collateralAmount);
            emit FundsWithdrawnFromCompound(_collateralAmount.add(_rewardsAmount), block.timestamp);
        }
    }

    /*
     * Get the current price of an asset from the protocol's persepctive
     */
    function getCompoundPrice(address singleAssetPriceFeed) public view returns (uint) {
        return COMPOUND.getPrice(singleAssetPriceFeed);
    }

    /*
     * Get the price feed address for an asset
     */
    function getCompPriceFeedAddress(address asset) public view returns (address) {
        return COMPOUND.getAssetInfoByAddress(asset).priceFeed;
    }

    /*
     * Gets the amount of reward tokens due to this contract address
     */
    function getCompUnclaimedRewards() public returns (uint) {
        return CometRewards(compRewardAddress).getRewardOwed(compAddress, address(this)).owed;
    }

    /*
     * Claims the reward tokens due to this contract address
     */
    function claimAaveRewards() public {
        address[] memory _wethAddress;
        _wethAddress[0] = WETH_ADDRESS;
        (, uint256[] memory _amounts) = aaveRewardsContract.claimAllRewardsToSelf(_wethAddress);
        if (_amounts.length == 0) revert NoAaveRewardsClaimed();
    }

    /*
     * Claims the reward tokens due to this contract address
     */
    function claimCompRewards() public {
        CometRewards(compRewardAddress).claim(compAddress, address(this), true);
    }

    function getAaveUnclaimedRewards() public view returns (uint256) {
        (, , , , , , uint256 liquidityRate, , ) = aaveDataProvider.getUserReserveData(WETH_ADDRESS, address(this));
        uint256 unclaimedRewards = (liquidityRate * getAaveWETHCurrentBalance()) / (10 ** 18);
        return unclaimedRewards;
    }
}
