// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { IPool } from "@aave/core-v3/contracts/interfaces/IPool.sol";
import { IPoolAddressesProvider } from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ThrivePiggy is Ownable {
	IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
	IPool public immutable POOL;
	IERC20 public immutable USDC;
	using SafeERC20 for IERC20;

	constructor(address _addressProvider, address _usdc, address _owner) {
		ADDRESSES_PROVIDER = IPoolAddressesProvider(_addressProvider);
		POOL = IPool(ADDRESSES_PROVIDER.getPool());
		USDC = IERC20(_usdc);
		transferOwnership(_owner);
	}

	function depositToAave(uint256 _amount) external onlyOwner {
		USDC.approve(address(POOL), _amount);
		POOL.supply(address(USDC), _amount, address(this), 0);
	}

	function withdrawFromAave(
		uint256 _amount,
		address _recipient
	) external onlyOwner {
		uint256 withdrawn = POOL.withdraw(address(USDC), _amount, _recipient);
		require(withdrawn == _amount, "Withdrawal amount mismatch");
	}

	function getAaveBalance()
		public
		view
		returns (
			uint256 totalCollateralBase,
			uint256 totalDebtBase,
			uint256 availableBorrowsBase,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		)
	{
		return POOL.getUserAccountData(address(this));
	}

	/**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
  function rescueTokens(address token, address to, uint256 amount) external onlyOwner {
    IERC20(token).safeTransfer(to, amount);
  }
}
