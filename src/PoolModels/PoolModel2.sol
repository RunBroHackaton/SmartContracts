
// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {RunBroToken} from "../RunBroToken.sol";

contract PoolModel2 {
    IERC20 public immutable i_wethToken; // i_wethToken -> WETH
    IERC20 public immutable i_rbToken; // i_rbToken -> RB

    uint public s_wethReserve;
    uint public s_rbReserve;

    uint256 public constant TOLERANCE_MARGIN =100;
    uint public s_totalSupply;
    mapping(address => uint) public balanceOf;

    address public s_owner;

    constructor(address _wethToken, address _rbToken) {
        // NOTE: This contract assumes that i_wethToken and i_rbToken
        // both have same decimals
        s_owner = msg.sender;
        i_wethToken = IERC20(_wethToken);
        i_rbToken = IERC20(_rbToken);

    }

    modifier onlyOwner(){
        require(msg.sender==s_owner,"Not s_owner");
        _;
    }

    function _mint(address _to, uint _amount) private {
        balanceOf[_to] += _amount;
        s_totalSupply += _amount;
    }

    function _burn(address _from, uint _amount) private {
        balanceOf[_from] -= _amount;
        s_totalSupply -= _amount;
    }

    function _update(uint _res0, uint _res1) private {
        s_wethReserve = _res0;
        s_rbReserve = _res1;  
    }

    function setIntialBalanceOfpool(uint256 _amount) public {
        i_rbToken.transferFrom(msg.sender, address(this), _amount);
        s_rbReserve = i_rbToken.balanceOf(address(this));
        s_wethReserve = i_wethToken.balanceOf(address(this));
    }

    function swap(address _tokenIn, uint _amountIn) external returns (uint amountOut) {
        require(
            _tokenIn == address(i_wethToken) || _tokenIn == address(i_rbToken),
            "invalid token"
        );

        bool isToken0 = _tokenIn == address(i_wethToken);

        (IERC20 tokenIn, IERC20 tokenOut, uint resIn, uint resOut) = isToken0
            ? (i_wethToken, i_rbToken, s_wethReserve, s_rbReserve)
            : (i_rbToken, i_wethToken, s_rbReserve, s_wethReserve);

        tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        uint amountIn = tokenIn.balanceOf(address(this)) - resIn;

        // 0.3% fee
        amountOut = (amountIn * 997) / 1000;

        (uint res0, uint res1) = isToken0
            ? (resIn + amountIn, resOut - amountOut)
            : (resOut - amountOut, resIn + amountIn);

        _update(res0, res1);
        tokenOut.transfer(msg.sender, amountOut);
    }
    
    // This function will be used to mint/add rbTokens to the pool, as per pool condition
    // if the ratio of added liquidity of rbTokens and wethTokens is less than ratio of both reserves by TOLERANCE_MARGIN
    // it will add liquidity other wise not.
    function addLiquidity() public {
        uint256 amt_toMint= _amountOfRBTokentoMint();
        uint256 balanceOfWETH = i_wethToken.balanceOf(address(this));
        if(s_rbReserve*balanceOfWETH - amt_toMint*s_wethReserve >= TOLERANCE_MARGIN){
            i_rbToken.mint(address(this), amt_toMint);
        }else{
            i_rbToken.mint(address(this), 10);
        }
        uint bal0 = i_wethToken.balanceOf(address(this)); // i_wethToken -> WETH
        uint bal1 = i_rbToken.balanceOf(address(this)); // i_rbToken -> RB

        _update(bal0, bal1);
    }

    function _amountOfRBTokentoMint() internal view returns(uint256){
        require(s_wethReserve >0 && s_rbReserve >0,"s_wethReserve is empty");
        uint256 balanceOfWETH = i_wethToken.balanceOf(address(this));
        uint256 amtToMint = (s_rbReserve* balanceOfWETH)/s_wethReserve;
        return amtToMint;
    }
}

interface IERC20 {
    function s_totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address s_owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function mint(address recipient, uint amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed s_owner, address indexed spender, uint amount);
}