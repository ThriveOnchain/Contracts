// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { IPool } from "@aave/core-v3/contracts/interfaces/IPool.sol";
import { IPoolAddressesProvider } from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import { IERC20 } from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ThrivePiggy is Ownable {
	IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
	IPool public immutable POOL;
	IERC20 public immutable USDC;

	constructor(address _addressProvider, address _usdc) {
		ADDRESSES_PROVIDER = IPoolAddressesProvider(_addressProvider);
		POOL = IPool(ADDRESSES_PROVIDER.getPool());
		USDC = IERC20(_usdc);
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

	function getAaveBalance() public view returns (uint256) {
		return POOL.getUserAccountData(address(this))[0]; // totalCollateralBase
	}
}
