// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

// Imports
// Import libreria test foundry
import "forge-std/Test.sol";
// Import contrato del que queremos hacer los tests
import "../src/StakingToken.sol";
// Import de la interfaz erc20
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

//Contract
contract StakingTokenTest is Test {
    // Variables
    // definir el objeto del SC del que vamos a hacer test
    StakingToken stakingToken;

    // Variables del constructor del SC
    string name_ = "Staking Token";
    string symbol_ = "STK";

    address randomUser = vm.addr(1);

    // FUNCION de inicializACION
    function setUp() public {
        // creacion del objeto del SC a testear con las variables del constructor
        stakingToken = new StakingToken(name_, symbol_);
    }

    function testStakingTokenMintsCorrectly() public {
        vm.startPrank(randomUser); // Simula que interactua randomUser

        uint256 amount_ = 1 ether;

        // Conosulta el  balance previous del token
        uint256 balanceBefore_ = IERC20(address(stakingToken)).balanceOf(randomUser);
        stakingToken.mint(amount_); // Se crea el token con el address randomUser
        // Conosulta el  balance after del token
        uint256 balanceAfter_ = IERC20(address(stakingToken)).balanceOf(randomUser);
        // Se comprueba que el usuario randomUser ha recibido el amount indicado en el minteo
        assert(balanceAfter_ - balanceBefore_ == amount_);

        vm.stopPrank(); // finaliza la direccion de la address para interactuar con el sc
    }
}
