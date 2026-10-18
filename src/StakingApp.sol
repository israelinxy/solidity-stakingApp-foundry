// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

// Imports
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingApp is Ownable {
    // Variables
    address public stakingToken;
    address public admin;
    uint256 public stakingPeriod;
    uint256 public fixedStakingAmount;
    uint256 public rewardPerPeriod;

    mapping(address => uint256) public userBalance;
    mapping(address => uint256) public elapsePeriod;

    // Events
    event ChangeStakingPeriod(uint256 newStakingPeriod_);
    event DepositTokens(address userAdress_, uint256 depositAmount_);
    event WithdrawTokens(address userAdress_, uint256 withdrawAmount_);
    event EtherSent(uint256 amount_);

    // Constructor
    constructor(
        address stakingToken_,
        address owner_,
        uint256 stakingPeriod_,
        uint256 fixedStakingAmount_,
        uint256 rewardPerPeriod_
    ) Ownable(owner_) {
        stakingToken = stakingToken_;
        admin = owner_;
        stakingPeriod = stakingPeriod_;
        fixedStakingAmount = fixedStakingAmount_;
        rewardPerPeriod = rewardPerPeriod_;
    }

    // Functions

    // External functions
    function depositTokens(uint256 tokenAmountDeposit_) external {
        require(tokenAmountDeposit_ == fixedStakingAmount, "Incorrect amount"); // Check to make sure the amount deposited is correct
        require(userBalance[msg.sender] == 0, "User already deposited"); // Avoid duplicate deposits

        IERC20(stakingToken).transferFrom(msg.sender, address(this), tokenAmountDeposit_); // Transfer the user's tokens to the contract
        userBalance[msg.sender] += tokenAmountDeposit_; // Update user's balance
        elapsePeriod[msg.sender] = block.timestamp;

        emit DepositTokens(msg.sender, tokenAmountDeposit_);
    }

    function withdrawStakingToken() external {
        // CEI PATTERN

        // CHECKS: Condition check
        // EFFECTS: Status and balance updates
        uint256 userBalance_ = userBalance[msg.sender];
        userBalance[msg.sender] = 0;
        // INTERACTIONS: Interaction with external contracts or addresses
        IERC20(stakingToken).transfer(msg.sender, userBalance_);

        emit WithdrawTokens(msg.sender, userBalance_);
    }

    function claimRewards() external {
        // CEI PATTERN

        // CHECKS: Condition check
        // 1. Verify user is staking
        require(userBalance[msg.sender] == fixedStakingAmount, "Not staking");

        // EFFECTS: Status and balance updates
        // 2. Verify staking period is the minimum required to earn a reward
        uint256 elapsePeriod_ = block.timestamp - elapsePeriod[msg.sender]; // elapse period -- período transcurrido
        require(elapsePeriod_ >= stakingPeriod, "Need to wait");
        // 3. Reset the staking time to zero to start over.
        elapsePeriod[msg.sender] = block.timestamp;

        // INTERACTIONS: Interaction with external contracts or addresses
        // 4. Transfer reward to EOA
        (bool success,) = msg.sender.call{value: rewardPerPeriod}("");
        require(success, "Transfer failed");
    }

    // function feedContract() external payable onlyOwner {}
    receive() external payable onlyOwner {
        emit EtherSent(msg.value);
    }

    function changeStakingPeriod(uint256 newStakingPeriod_) external onlyOwner {
        stakingPeriod = newStakingPeriod_;

        emit ChangeStakingPeriod(newStakingPeriod_);
    }
}
