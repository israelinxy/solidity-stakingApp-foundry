// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

// Imports
import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

//Contract
contract StakingTokenTest is Test {
    StakingToken stakingToken; // Define the SC object we're going to test.

    // SC constructor variables
    string name_ = "Staking Token";
    string symbol_ = "STK";

    address randomUser = vm.addr(1);

    // Initialization function
    function setUp() public {
        stakingToken = new StakingToken(name_, symbol_); // Create the SC object to be tested
    }

    function testStakingTokenMintsCorrectly() public {
        vm.startPrank(randomUser); // Simulate interaction with randomUser

        uint256 amount_ = 1 ether;

        uint256 balanceBefore_ = IERC20(address(stakingToken)).balanceOf(randomUser); // Check previous token balance
        stakingToken.mint(amount_); // Mints stakingToken to randomUser address
        uint256 balanceAfter_ = IERC20(address(stakingToken)).balanceOf(randomUser); // Check after token balance

        assert(balanceAfter_ - balanceBefore_ == amount_); //Verify randomUser received stakingToken minted

        vm.stopPrank(); // End Simulate interaction with randomUser
    }
}
