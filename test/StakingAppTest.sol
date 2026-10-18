// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

// Imports
import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../src/StakingApp.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingAppTest is Test {
    // Declare imported SC items
    StakingToken stakingToken; // It's declared first because we need it for the staking app.
    StakingApp stakingApp;

    // StakingToken parameters
    string name_ = "Staking Token";
    string symbol_ = "STK";

    // StakingApp parameters
    address owner_ = vm.addr(1);
    uint256 stakingPeriod_ = 100000000000;
    uint256 fixedStakingAmount_ = 10;
    uint256 rewardPerPeriod_ = 1 ether;

    address randomUser = vm.addr(2);

    // Function setup()
    function setUp() external {
        // inicializar objetos sc con sus parametros
        stakingToken = new StakingToken(name_, symbol_);
        stakingApp =
            new StakingApp(address(stakingToken), owner_, stakingPeriod_, fixedStakingAmount_, rewardPerPeriod_);
    }

    // Verify both smart-contracts deployed correctly
    function testStakingTokenCorrectlyDeployed() external view {
        assert(address(stakingToken) != address(0));
    }

    function testStakingAppCorrectlyDeployed() external view {
        assert(address(stakingApp) != address(0));
    }

    // StakingApp functions tests
    function testShoulRevertIfNotOwner() external {
        uint256 newStakingPeriod_ = 1;

        vm.expectRevert();
        stakingApp.changeStakingPeriod(newStakingPeriod_);
    }

    function testShouldChangeStakingPeriod() external {
        vm.startPrank(owner_);
        uint256 newStakingPeriod_ = 1;

        uint256 stakingPeriodBefore = stakingApp.stakingPeriod();
        stakingApp.changeStakingPeriod(newStakingPeriod_);
        uint256 stakingPeriodAfter = stakingApp.stakingPeriod();

        assert(stakingPeriodBefore != newStakingPeriod_);
        assert(stakingPeriodAfter == newStakingPeriod_);

        vm.stopPrank();
    }

    function testContratReceiveEtherCorrectly() external {
        vm.startPrank(owner_); // Simulate calls from the specified address
        vm.deal(owner_, 1 ether); // Sets the balance of an address

        uint256 etherValue = 1 ether;

        uint256 balanceBefore = address(stakingApp).balance; // Check the balance of an address
        (bool success,) = address(stakingApp).call{value: etherValue}(""); // Sends ether to address
        require(success, "Transfer failed"); // Check the transfer
        uint256 balanceAfter = address(stakingApp).balance;

        assert(balanceAfter - balanceBefore == etherValue); // Check the amount has been sent

        vm.stopPrank(); // End of impersonating function calls
    }

    // Deposit function tests
    function testIncorrectAmountShouldRevert() external {
        vm.startPrank(randomUser);

        uint256 depositAmount = 1;
        vm.expectRevert("Incorrect amount");
        stakingApp.depositTokens(depositAmount);

        vm.stopPrank();
    }

    function testDepositTokensCorrectly() external {
        vm.startPrank(randomUser); // address que va a depositar token

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount); //minteo del token

        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount); // Aprobar la address que va a poder gastar tokens
        stakingApp.depositTokens(tokenAmount); // deposito de los tokens
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        vm.stopPrank();
    }

    function testUserCanNotDepositMoreThanOnce() external {
        vm.startPrank(randomUser); // address que va a depositar token

        // First deposit
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount); //minteo del token

        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount); // Aprobar la address que va a poder gastar tokens
        stakingApp.depositTokens(tokenAmount); // deposito de los tokens
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        // Second deposit
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        vm.expectRevert("User already deposited");
        stakingApp.depositTokens(tokenAmount);

        vm.stopPrank();
    }

    // withdraw function tests
    function testCanOnlyWithdraw0WithoutDeposit() external {
        vm.startPrank(randomUser);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        stakingApp.withdrawStakingToken();
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);

        assert(userBalanceAfter == userBalanceBefore);

        vm.stopPrank();
    }

    function testWithdrawTokensCorrectly() external {
        vm.startPrank(randomUser);

        // 1. Deposit Tokens in stakingApp
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount); //minteo del token

        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount); // Aprobar la address que va a poder gastar tokens
        stakingApp.depositTokens(tokenAmount); // deposito de los tokens
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        // 2. Withdraw Tokens from stakingApp to randomUser

        uint256 walletBalanceBefore = IERC20(stakingToken).balanceOf(randomUser);
        uint256 stakedBalanceBefore = stakingApp.userBalance(randomUser);
        stakingApp.withdrawStakingToken();
        uint256 walletBalanceAfter = IERC20(stakingToken).balanceOf(randomUser);
        uint256 stakedBalanceAfter = stakingApp.userBalance(randomUser);

        assert(walletBalanceAfter == walletBalanceBefore + stakedBalanceBefore);
        assert(stakedBalanceAfter == 0);

        vm.stopPrank();
    }

    // ClaimRewards function tests
    function testCanNotClaimIfNotStaking() external {
        vm.startPrank(randomUser);

        vm.expectRevert("Not staking");
        stakingApp.claimRewards();

        vm.stopPrank();
    }

    function testCanNotClaimIfNotElapsedTime() external {
        vm.startPrank(randomUser);

        // 1. Deposit Tokens in stakingApp
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount); //minteo del token

        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount); // Approve the address that will be able to spend tokens
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        // 2. Claim Rewards
        vm.expectRevert("Need to wait");
        stakingApp.claimRewards();

        vm.stopPrank();
    }

    function testShoulRevertIfNotEther() external {
        vm.startPrank(randomUser);

        // 1. Deposit Tokens in stakingApp
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount); //Token minting

        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount); // Approve the address that will be able to spend tokens
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        // 2. Claim Rewards
        vm.warp(block.timestamp + stakingPeriod_);
        vm.expectRevert("Transfer failed");
        stakingApp.claimRewards();

        vm.stopPrank();
    }

    function testCanClaimRewardsCorrectly() external {
        // 1. Deposit Tokens in stakingApp
        vm.startPrank(randomUser);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount); // Token minting

        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount); // Approve the address that will be able to spend tokens
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        vm.stopPrank();

        // 2. Send funds to StakingApp
        vm.startPrank(owner_);

        uint256 etherAmount = 10000 ether;
        vm.deal(owner_, etherAmount);
        (bool success,) = address(stakingApp).call{value: etherAmount}("");
        require(success, "Test transfer failed");

        vm.stopPrank();

        // 3. Claim Rewards
        vm.startPrank(randomUser);

        vm.warp(block.timestamp + stakingPeriod_);
        uint256 etherAmountBefore = address(randomUser).balance;
        stakingApp.claimRewards();
        uint256 etherAmountAfter = address(randomUser).balance;
        uint256 elapsedPeriod = stakingApp.elapsePeriod(randomUser);

        assert(etherAmountAfter - etherAmountBefore == rewardPerPeriod_);
        assert(elapsedPeriod == block.timestamp);

        vm.stopPrank();
    }
}
