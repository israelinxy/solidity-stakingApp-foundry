// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

// Imports
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingApp is Ownable {
  // 1. StakingToken address
  // 2. Admin

  // Variables
  address public stakingToken;
  address public admin;
  uint256 public stakingPeriod;
  uint256 public fixedStakingAmount;
  uint256 public rewardPerPeriod;

  mapping(address => uint256) public userBalance;
  mapping(address => uint256) public elapsePeriod;

  // Modificadores


  // Eventos
  event ChangeStakingPeriod(uint256 newStakingPeriod_);
  event DepositTokens(address userAdress_, uint256 depositAmount_);
  event WithdrawTokens(address userAdress_, uint256 withdrawAmount_);
  event EtherSent(uint256 amount_);

  // Constructor
  constructor(address stakingToken_, address owner_, uint256 stakingPeriod_, uint256 fixedStakingAmount_, uint256 rewardPerPeriod_) Ownable(owner_) {
    stakingToken = stakingToken_;
    admin = owner_;
    stakingPeriod = stakingPeriod_;
    fixedStakingAmount = fixedStakingAmount_;
    rewardPerPeriod = rewardPerPeriod_;
  }


  // Funciones

  // External functions
  
  function depositTokens(uint256 tokenAmountDeposit_) external {
    require(tokenAmountDeposit_ == fixedStakingAmount, "Incorrect amount"); // Comprueba que la cantidad depositada sea la correcta.
    require(userBalance[msg.sender] == 0, "User already deposited"); // evitar depósitos duplicados

    IERC20(stakingToken).transferFrom(msg.sender, address(this), tokenAmountDeposit_); // Transfiere los tokens del usuario al contrato77
    userBalance[msg.sender] += tokenAmountDeposit_; // Actualiza el saldo del usuario
    elapsePeriod[msg.sender] = block.timestamp;

    emit DepositTokens(msg.sender, tokenAmountDeposit_);
  }

  function withdrawStakingToken() external {
    // CEI PATTERN
    // CHECKS
    // EFFECTS
    uint256 userBalance_ = userBalance[msg.sender];
    userBalance[msg.sender] = 0;
    // INTERACTIONS    
    IERC20(stakingToken).transfer(msg.sender, userBalance_);
    
    emit WithdrawTokens(msg.sender, userBalance_);
  }

  function claimRewards() external {
    // CEI PATTERN

    // CHECKS: comprobacion de condiciones
    // 1. comprobar que el user esta haciendo staking
    require(userBalance[msg.sender] == fixedStakingAmount, "Not staking");

    
    // EFFECTS: actualizaciones de estado, balances
    // 2. comprobar que el tiempo de staking es el minimo para obtener reward
    uint256 elapsePeriod_ = block.timestamp - elapsePeriod[msg.sender]; // elapse period -- período de transcurso
    require(elapsePeriod_ >= stakingPeriod, "Need to wait"); 
    // 3. actualizacmos el tiempo de staking a cero para empezar de nuevo
    elapsePeriod[msg.sender] = block.timestamp;
    
    
    // INTERACTIONS: interaccion con contratos o direcciones externas
    // 4. hacer la transferencia del reward a la eoa/sc
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

  // Internal functions








}