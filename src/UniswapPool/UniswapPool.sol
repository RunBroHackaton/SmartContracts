// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import {PoolInitializer} from "@uniswap/v3-periphery/contracts/base/PoolInitializer.sol";
// import {IUniSwapV3factory} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
// import {IUniswapV3Pool} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
// import {IPoolInitializer} from '@uniswap/v3-periphery/contracts/interfaces/IPoolInitializer.sol';
// import {PeripheryImmutableState} from '@uniswap/v3-periphery/contracts/base/PeripheryImmutableState.sol';
// contract Pool is IPoolInitializer, PeripheryImmutableState {
//     function createAndInitializePoolIfNecessary(
//         address token0,
//         address token1,
//         uint24 fee,
//         uint160 sqrtPriceX96
//     ) external payable override returns (address pool) {
//         require(token0 < token1);
//         pool = IUniswapV3Factory(factory).getPool(token0, token1, fee);

//         if (pool == address(0)) {
//             pool = IUniswapV3Factory(factory).createPool(token0, token1, fee);
//             IUniswapV3Pool(pool).initialize(sqrtPriceX96);
//         } else {
//             (uint160 sqrtPriceX96Existing, , , , , , ) = IUniswapV3Pool(pool).slot0();
//             if (sqrtPriceX96Existing == 0) {
//                 IUniswapV3Pool(pool).initialize(sqrtPriceX96);
//             }
//         }
//     }
// }