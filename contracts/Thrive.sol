// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./lib/thriveutils.sol";

contract Thrive is ReentrancyGuard {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.UintSet;

	// State variables
	address public immutable usdc;
	uint256 public constant EARLY_WITHDRAWAL_FEE_PERCENTAGE = 1000; // 10% fee represented as 1000 basis points
	uint256 public constant DAYS_PER_YEAR = 365;
	uint256 public constant AAVE_APY = 200; // 2% APY, represented as 200 basis points
	uint256 public constant SCALE = 1e18; // Used for precision in calculations

	//SAVELOCK ITEMS STATES ........................................
	// Mapping to store SaveLock structs
	mapping(uint256 => ThriveUtils.SaveLock) public saveLocks;
	// EnumerableSet to keep track of user's save locks
	mapping(address => EnumerableSet.UintSet) private userActiveSaveLocks;
	mapping(address => EnumerableSet.UintSet) private userInActiveSaveLocks;

	// EnumerableSet to keep track of all save locks
	EnumerableSet.UintSet private allActiveSaveLocks;
	EnumerableSet.UintSet private allInActiveSaveLocks;

	// Counter for generating unique save lock IDs
	uint256 private nextSaveLockId = 1;

	//TARGET LOCK STATES...............................................
	mapping(uint256 => ThriveUtils.TargetSavings) public targetSavings;
	mapping(address => EnumerableSet.UintSet) private userTargetSavings;
	EnumerableSet.UintSet private allTargetSavings;

	uint256 private nextTargetSavingsId = 1;

	//user rewards on savings
	mapping(address => uint256) public userUSDRewards;

	// EVENTS
	//SaveLock events
	event SaveLockCreated(
		address indexed user,
		address indexed token,
		uint256 amount,
		ThriveUtils.LockPeriod lockPeriod,
		uint256 timestamp,
		uint256 indexed lockId
	);

	event FundsWithdrawn(
		address indexed user,
		address indexed token,
		uint256 amountWithdrawn,
		uint256 rewardAmount,
		uint256 fee,
		uint256 timestamp,
		uint256 indexed lockId
	);
	//Target lock events
	event TargetSavingsCreated(
		address indexed user,
		string purpose,
		uint256 targetAmount,
		uint256 indexed startTime,
		uint256 endTime,
		uint256 indexed savingsId
	);

	event TargetSavingsUpdated(
		uint256 indexed savingsId,
		uint256 amountAdded,
		uint256 newTotalAmount
	);

	event TargetSavingsCompleted(
		uint256 indexed savingsId,
		uint256 totalAmount,
		uint256 rewardAmount
	);

	//rewards events
	event SafeLockRewardsClaimed(address indexed user, uint256 amount);

	//Modifiers

	modifier onlySupportedToken(address _token) {
		require(_token == address(usdc), "Unsupported token");
		_;
	}

	//CONSTRUCTOR /////
	constructor(address _usdc) {
		require(_usdc != address(0), "Invalid USDC address");
		usdc = _usdc;
	}

	//TARGET SAVE DOMAIN ~~~~

	/**
	 * @dev Creates a new target savings goal
	 * @param _purpose The purpose of the savings goal
	 * @param _targetAmount The target amount to save
	 * @param _durationDays The duration of the savings period in days
	 */

	function createTargetSavings(
		string memory _purpose,
		uint256 _targetAmount,
		ThriveUtils.LockPeriod _durationDays
	) external {
		require(_targetAmount > 0, "Target amount must be greater than 0");

		uint256 lockDuration = ThriveUtils.getLockDuration(_durationDays);

		uint256 newSavingsId = nextTargetSavingsId++;
		uint256 startTime = block.timestamp;
		uint256 endTime = startTime.add(lockDuration.mul(1 days));

		targetSavings[newSavingsId] = ThriveUtils.TargetSavings({
			owner: msg.sender,
			purpose: _purpose,
			targetAmount: _targetAmount,
			currentAmount: 0,
			startTime: startTime,
			endTime: endTime,
			accumulatedRewards: 0,
			completed: false,
			lastDepositTime: 0
		});

		userTargetSavings[msg.sender].add(newSavingsId);
		allTargetSavings.add(newSavingsId);

		emit TargetSavingsCreated(
			msg.sender,
			_purpose,
			_targetAmount,
			startTime,
			endTime,
			newSavingsId
		);
	}

	function addToTargetSavings(
		uint256 _savingsId,
		uint256 _amount
	) external nonReentrant {
		require(
			userTargetSavings[msg.sender].contains(_savingsId),
			"Target savings not found or not owned by user"
		);

		ThriveUtils.TargetSavings storage savings = targetSavings[_savingsId];

		require(!savings.completed, "Target savings already completed");
		require(block.timestamp < savings.endTime, "Savings period has ended");

		IERC20(usdc).safeTransferFrom(msg.sender, address(this), _amount);

		uint256 newRewards = 0;
		if (savings.lastDepositTime != 0) {
			newRewards = _calculateRewardsForDeposit(
				savings.currentAmount,
				savings.lastDepositTime,
				block.timestamp
			);
		}

		savings.accumulatedRewards = savings.accumulatedRewards.add(newRewards);
		savings.currentAmount = savings.currentAmount.add(_amount);
		savings.lastDepositTime = block.timestamp;

		if (savings.currentAmount >= savings.targetAmount) {
			savings.completed = true;
		}

		emit TargetSavingsUpdated(_savingsId, _amount, savings.currentAmount);
	}

	function _calculateRewardsForDeposit(
		uint256 _amount,
		uint256 _startTime,
		uint256 _endTime
	) internal pure returns (uint256) {
		uint256 durationInSeconds = _endTime.sub(_startTime);
		uint256 annualRewardRate = AAVE_APY.mul(1e18).div(10000); // Convert basis points to a decimal, scaled by 1e18
		uint256 rewardRate = annualRewardRate.div(365 days);
		uint256 reward = _amount.mul(rewardRate).mul(durationInSeconds).div(
			1e18
		);
		return reward;
	}

	//withdraw the and delete target save

	function completeTargetSavings(uint256 _savingsId) external nonReentrant {
		ThriveUtils.TargetSavings storage savings = targetSavings[_savingsId];
		require(
			savings.owner == msg.sender,
			"only owner can complete target saivngs"
		);
		require(
			userTargetSavings[msg.sender].contains(_savingsId),
			"Savings dosen't exists"
		);

		uint256 amountToTransfer = savings.currentAmount;
		uint256 rewardsToTransfer = savings.accumulatedRewards;

		if (!savings.completed && block.timestamp < savings.endTime) {
			uint256 earlyWithdrawalFee = amountToTransfer.mul(1200).div(10000); // 12% fee
			amountToTransfer = amountToTransfer.sub(earlyWithdrawalFee);
		}

		// subtract 30% protocol fees on the rewards
		uint256 protocolRewardShare = rewardsToTransfer.mul(3000).div(10000);
		rewardsToTransfer = rewardsToTransfer.sub(protocolRewardShare);

		IERC20(usdc).safeTransfer(
			savings.owner,
			amountToTransfer.add(rewardsToTransfer)
		);

		// Transfer protocol's share of rewards to fee

		userTargetSavings[savings.owner].remove(_savingsId);
		allTargetSavings.remove(_savingsId);

		// delete targetSavings[_savingsId];

		emit TargetSavingsCompleted(
			_savingsId,
			savings.currentAmount,
			savings.accumulatedRewards
		);
	}

	//SAVE LOCK DOMAIN~~~
	/**
	 * @dev Creates a new save lock for the user
	 * @param _amount The amount of USDC to lock
	 * @param _lockPeriod The duration of the lock
	 */

	function saveLockFunds(
		address _token,
		string memory _title,
		uint256 _amount,
		ThriveUtils.LockPeriod _lockPeriod
	) external nonReentrant onlySupportedToken(_token) {
		require(_amount > 1e6, "Amount must be greater than 1 USDC");

		uint256 lockDuration = ThriveUtils.getLockDuration(_lockPeriod);
		uint256 newLockId = nextSaveLockId++;

		// Transfer USDC from user to contract
		IERC20(usdc).safeTransferFrom(msg.sender, address(this), _amount);

		// Create new SaveLock
		saveLocks[newLockId] = ThriveUtils.SaveLock({
			id: newLockId,
			owner: msg.sender,
			amount: _amount,
			withdrawnAmount: 0,
			title: _title,
			lockDuration: lockDuration,
			startTime: block.timestamp,
			lockToken: usdc,
			withdrawn: false,
			accumulatedRewards: 0
		});

		// Add to user's active save locks and all active save locks
		userActiveSaveLocks[msg.sender].add(newLockId);

		allActiveSaveLocks.add(newLockId);

		emit SaveLockCreated(
			msg.sender,
			usdc,
			_amount,
			_lockPeriod,
			block.timestamp,
			newLockId
		);
	}

	/**
	 * @dev Allows user to withdraw funds from a save lock
	 * @param _lockId The ID of the save lock to withdraw from
	 */

	function withdrawLockedFunds(uint256 _lockId) external nonReentrant {
		require(
			userActiveSaveLocks[msg.sender].contains(_lockId),
			"SaveLock not found or not owned by user"
		);

		ThriveUtils.SaveLock storage lock = saveLocks[_lockId];
		require(lock.amount > 0, "SaveLock already withdrawn");

		uint256 lockEndTime = lock.startTime.add(lock.lockDuration);
		uint256 amountToTransfer = lock.amount;
		uint256 fee = 0;
		uint256 rewardAmount = 0;

		require(
			block.timestamp >
				lock.startTime.add(lock.lockDuration.mul(60).div(100)),
			"Cannot withdraw before 60% of lock duration"
		);

		if (block.timestamp < lockEndTime) {
			fee = lock.amount.mul(EARLY_WITHDRAWAL_FEE_PERCENTAGE).div(10000);
			amountToTransfer = lock.amount.sub(fee);
		} else {
			uint256 daysLocked = lock.lockDuration.div(1 days);
			rewardAmount = calculateSaveLockReward(lock.amount, daysLocked);
			userUSDRewards[msg.sender] = userUSDRewards[msg.sender].add(
				rewardAmount
			);
			lock.accumulatedRewards = rewardAmount;
		}

		lock.withdrawnAmount = amountToTransfer;
		lock.withdrawn = true;

		// Remove save lock from active sets
		userActiveSaveLocks[msg.sender].remove(_lockId);
		allActiveSaveLocks.remove(_lockId);

		//add safe lock to inactiveset
		userInActiveSaveLocks[msg.sender].add(_lockId);
		allInActiveSaveLocks.add(_lockId);

		// Transfer funds to user
		IERC20(usdc).safeTransfer(msg.sender, amountToTransfer);

		emit FundsWithdrawn(
			msg.sender,
			usdc,
			amountToTransfer,
			rewardAmount,
			fee,
			block.timestamp,
			_lockId
		);
	}

	function claimSafeLockRewards() external nonReentrant {
		uint256 rewardsAmount = userUSDRewards[msg.sender];
		require(rewardsAmount > 0, "No rewards to claim");

		userUSDRewards[msg.sender] = 0;

		IERC20(usdc).safeTransfer(msg.sender, rewardsAmount);

		emit SafeLockRewardsClaimed(msg.sender, rewardsAmount);
	}

	/**
	 * @dev Calculates the reward for a completed save lock
	 * @param amount The locked amount
	 * @param daysLocked The number of days the amount was locked
	 * @return The calculated reward amount
	 */
	function calculateSaveLockReward(
		uint256 amount,
		uint256 daysLocked
	) internal pure returns (uint256) {
		uint256 annualReward = amount.mul(AAVE_APY).div(10000);
		uint256 dailyReward = annualReward.div(DAYS_PER_YEAR);
		return dailyReward.mul(daysLocked);
	}

	//GETHERS FUNCTIONS
	// Save Lock Getter functions

	function getUserActiveSaveLockIds(
		address _user
	) external view returns (uint256[] memory) {
		return userActiveSaveLocks[_user].values();
	}

	function getUserInActiveSaveLockIds(
		address _user
	) external view returns (uint256[] memory) {
		return userInActiveSaveLocks[_user].values();
	}

	function getAllActiveSaveLockIds()
		external
		view
		returns (uint256[] memory)
	{
		return allActiveSaveLocks.values();
	}

	function getAllInActiveSaveLockIds()
		external
		view
		returns (uint256[] memory)
	{
		return allInActiveSaveLocks.values();
	}

	function getSaveLockDetails(
		uint256 _lockId
	) external view returns (ThriveUtils.SaveLock memory) {
		return saveLocks[_lockId];
	}

	function getUnclaimedSafeLockRewards(
		address _user
	) external view returns (uint256) {
		return userUSDRewards[_user];
	}

	//target savings
	function getUserActiveTargetSavingsIds(
		address _user
	) external view returns (uint256[] memory) {
		return userTargetSavings[_user].values();
	}

	function getAllTargetSavingsIds() external view returns (uint256[] memory) {
		return allTargetSavings.values();
	}

	function getTargetSavingsDetails(
		uint256 _savingsId
	) external view returns (ThriveUtils.TargetSavings memory) {
		return targetSavings[_savingsId];
	}
}
