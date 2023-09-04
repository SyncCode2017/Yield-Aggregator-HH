// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
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
import "./interfaces/IYieldAggregator.sol";

/** @title A yield aggregator contract for optimising users APY in Aave and compoundComet.
 *  @author Abolaji
 *  @dev It monitors APY of both Aave and compoundComet and deposit the user's WETH tokens into the protocol
 *  with higher APY.
 */
contract YieldAggregator is IYieldAggregator, ReentrancyGuard, Ownable {
    using ERC165Checker for address;
    using SafeERC20 for IERC20;
    /// @dev WETH contract address
    address public immutable wethAddress;
    /// @dev Number of days in a year
    uint48 public constant DAYS_PER_YEAR = 365;
    /// @dev Seconds in a day
    uint48 public constant SECONDS_PER_DAY = 60 * 60 * 24;
    /// @dev Compound V3 comet contract address
    address public immutable compAddress;
    /// @dev Seconds in a year
    uint96 public constant SECONDS_PER_YEAR = SECONDS_PER_DAY * DAYS_PER_YEAR;
    /// @dev Compound rewards contract address
    address public immutable compRewardAddress;
    /// @dev Compound V3 comet contract
    Comet public immutable compoundComet;
    uint96 public constant RAY = 10 ** 27;
    uint256 public constant MAX_UINT = type(uint256).max;
    /// @dev Aave V3 lending pool address provider
    IPoolAddressesProvider public immutable lendingPoolAddressProvider;
    /// @dev Aave V3 data provider contract
    IPoolDataProvider public immutable aaveDataProvider;
    /// @dev Aave V3 lending pool contract
    IPool public aaveLendingPool;

    /// @notice Initialises the contract
    /// @param _wethAddress WETH contract address
    /// @param _cometAddress Compound Comet contract address
    /// @param _cometRewardAddress Compound Comet rewards contract address
    /// @param _aaveProtocolDataProvider Aave protocol data provider contract address
    /// @param _aavePoolAddressesProvider Aave lending pool addresses provider
    constructor(address _wethAddress, address _cometAddress, address _cometRewardAddress, address _aaveProtocolDataProvider, address _aavePoolAddressesProvider) {
        // initialise the contract
        wethAddress = _wethAddress;
        aaveDataProvider = IPoolDataProvider(_aaveProtocolDataProvider);
        lendingPoolAddressProvider = IPoolAddressesProvider(_aavePoolAddressesProvider);
        aaveLendingPool = IPool(lendingPoolAddressProvider.getPool());
        compAddress = _cometAddress;
        compRewardAddress = _cometRewardAddress;
        compoundComet = Comet(compAddress);
    }

    /// @notice Allow the owner to deposit to Aave and Compound
    /// @dev only accepts WETH token
    /// @param _amount in wei to be deposited
    function depositWETH(uint256 _amount) external nonReentrant onlyOwner {
        _recieveWETH(msg.sender, _amount);
        // compare the apy of Aave and Compound deposit to the one with the highest APY
        if (getAaveCurrentWETHAPY() >= getCompoundCurrentWETHAPY()) {
            _depositWETHToAave(_amount);
        } else {
            _depositWETHToCompound(_amount);
        }
    }

    /// @notice Allows the owner to withraw his asset from Aave or Compound
    function withdrawWETH() external nonReentrant onlyOwner {
        _withdrawWETHFromAave();
        _withdrawWETHFromCompound();
        uint256 _contractBalance = IERC20(wethAddress).balanceOf(address(this));
        if (_contractBalance <= 0) revert InsufficientBalance();
        _sendWETH(owner(), _contractBalance);
        emit FundsWithdrawn(owner(), _contractBalance);
    }

    /// @notice Allows the caller to move the asset the protocol with higher apy
    function rebalanceWETH() external nonReentrant {
        uint256 _wethBalanceAave = getAaveWETHCurrentBalance();
        uint256 _wethBalanceCompound = getCompoundWETHCurrentBalance(); //compBalance;
        if (getAaveCurrentWETHAPY() > getCompoundCurrentWETHAPY() && _wethBalanceCompound > _wethBalanceAave) {
            _withdrawWETHFromCompound();
            uint256 _contractBalance = IERC20(wethAddress).balanceOf(address(this));
            _depositWETHToAave(_contractBalance);
            emit FundsMovedFromCompoundToAave(_contractBalance);
        } else if (getAaveCurrentWETHAPY() < getCompoundCurrentWETHAPY() && _wethBalanceCompound < _wethBalanceAave) {
            _withdrawWETHFromAave();
            uint256 _contractBalance = IERC20(wethAddress).balanceOf(address(this));
            _depositWETHToCompound(_contractBalance);
            emit FundsMovedFromAaveToCompound(_contractBalance);
        } else {
            revert NoRebalanceRequired();
        }
    }

    /// @dev Returns current Aave APY
    function getAaveCurrentWETHAPY() public view returns (uint256) {
        uint256 _userDepositAmount = RAY; // hypothetical
        DataTypes.ReserveData memory reserveData = aaveLendingPool.getReserveData(wethAddress);
        uint256 currentLiquidityRate = reserveData.currentLiquidityRate;
        uint256 currentLiquidityIndex = reserveData.liquidityIndex;
        uint256 _depositAPR = (currentLiquidityRate * (10 ** 18)) / RAY;
        uint256 apyNumerator = (currentLiquidityIndex * _depositAPR) / _userDepositAmount;
        uint256 apyDenominator = (10 ** 18);
        uint256 apy = (apyNumerator * RAY) / apyDenominator;
        return apy;
    }

    /// @dev Returns current Compound WETH APY
    function getCompoundCurrentWETHAPY() public view returns (uint256) {
        uint256 _utilization = compoundComet.getUtilization();
        uint256 _supplyRate = compoundComet.getSupplyRate(_utilization);
        uint256 _supplyAPR = (((_supplyRate * SECONDS_PER_YEAR) * RAY) / (10 ** 18));
        return _supplyAPR;
    }

    /// @dev Returns current contract balance in Aave
    function getAaveWETHCurrentBalance() public view returns (uint256) {
        (uint256 currentATokenBalance, , , , , , , , ) = aaveDataProvider.getUserReserveData(wethAddress, address(this));
        return currentATokenBalance;
    }

    /// @dev Returns current contract balance in Compound
    function getCompoundWETHCurrentBalance() public view returns (uint256) {
        uint256 _compBalance = compoundComet.userCollateral(address(this), wethAddress).balance;
        return _compBalance;
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
        if (IERC20(wethAddress).allowance(_from, address(this)) < _amount) revert ApproveRightAmount();
        // receive deposit and update state
        IERC20(wethAddress).safeTransferFrom(_from, address(this), _amount);
    }

    /// @notice Transfer Weth from the contract to the recipient
    /// @param _to The recipient address
    /// @param _amount The amount of tokens to transfer
    function _sendWETH(address _to, uint256 _amount) internal {
        address payable _recipient = payable(_to);
        // send token to the recipient
        IERC20(wethAddress).safeTransfer(_recipient, _amount);
    }

    /// @dev Supplies WETH asset to Aave V3 protocol
    function _depositWETHToAave(uint256 _amount) internal {
        IERC20(wethAddress).approve(address(aaveLendingPool), _amount);
        try aaveLendingPool.deposit(wethAddress, _amount, address(this), 0) {
            emit FundsDepositedToAave(_amount);
        } catch {
            revert DepositToAaveFailed();
        }
    }

    /// @dev Withdraws WETH asset from Compound V3 protocol
    function _withdrawWETHFromAave() internal {
        uint256 _amount = getAaveWETHCurrentBalance();
        if (_amount > 0) {
            try aaveLendingPool.withdraw(wethAddress, _amount, address(this)) {
                emit FundsWithdrawnFromAave(_amount);
            } catch {
                revert AaveWithdrawalFailed();
            }
        }
    }

    /// @dev Supplies WETH asset to Compound V3 protocol
    function _depositWETHToCompound(uint256 _amount) internal {
        IERC20(wethAddress).approve(address(compoundComet), _amount);
        try compoundComet.supply(wethAddress, _amount) {
            emit FundsDepositedToCompound(_amount);
        } catch {
            revert DepositToCompoundFailed();
        }
    }

    /// @dev Withdraws WETH asset from Aave V3 protocol
    function _withdrawWETHFromCompound() internal {
        uint256 _amount = getCompoundWETHCurrentBalance();
        if (_amount > 0) {
            try compoundComet.withdraw(wethAddress, _amount) {
                emit FundsWithdrawnFromCompound(_amount);
            } catch {
                revert CompoundWithdawalFailed();
            }
        }
    }
}
