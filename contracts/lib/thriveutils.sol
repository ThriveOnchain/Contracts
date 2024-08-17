// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ThriveUtils {
	struct AutoSave {
		uint256 totalSavings;
		address savingsCurrency;
		uint256 nextWithdrawalTime;
		uint256 frequency;
		uint256 autoSaveAmount;
	}

	enum LockPeriod {
		TwoMinutes,
		ThreeMinutes,
		FiveMinutes,
		SevenMinutes,
		TenMinutes
	}

	struct SaveLock {
		address owner;
		uint256 amount;
		string title;
		uint256 lockDuration;
		uint256 startTime;
		address lockToken;
	}

	struct TargetSavings {
		address owner;
		string purpose;
		uint256 targetAmount;
		uint256 currentAmount;
		uint256 startTime;
		uint256 endTime;
		bool completed;
		uint256 accumulatedRewards;
		uint256 lastDepositTime;
	}

	// Constants for lock durations

	uint256 constant TWO_MINUTES = 2 minutes;
	uint256 constant THREE_MINUTES = 3 minutes;
	uint256 constant FIVE_MINUTES = 5 minutes;
	uint256 constant SEVEN_MINUTES = 7 minutes;
	uint256 constant TEN_MINUTES = 10 minutes;

	function getLockDuration(
		LockPeriod _lockPeriod
	) internal pure returns (uint256) {
		if (_lockPeriod == LockPeriod.TwoMinutes) {
			return TWO_MINUTES;
		} else if (_lockPeriod == LockPeriod.ThreeMinutes) {
			return THREE_MINUTES;
		} else if (_lockPeriod == LockPeriod.FiveMinutes) {
			return FIVE_MINUTES;
		} else if (_lockPeriod == LockPeriod.SevenMinutes) {
			return SEVEN_MINUTES;
		} else if (_lockPeriod == LockPeriod.TenMinutes) {
			return TEN_MINUTES;
		} else {
			revert("Invalid lock period");
		}
	}
}
