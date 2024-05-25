// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {PoolModel2} from "./PoolModels/PoolModel2.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
}

contract MarketPlace {

    address public owner;
    PoolModel2 public pool;
    IWETH public weth;

    struct Shoe {
        uint256 id;
        string name;
        string brand;
        string image;
        uint256 cost;
        uint256 RB_Factor;
        uint256 quantity; // let's keep it one
        address lister;
    }

    struct Order {
        uint256 time;
        Shoe shoe;
    }

    mapping(uint256 => Shoe) public shoes;
    mapping(address => mapping(uint256 => Order)) public orders;
    mapping(address => uint256) public orderCount;

    mapping(address => mapping (uint256 => bool)) public hasUserPurchased_A_Shoe;

    event Buy(address buyer, uint256 orderId, uint256 shoeId, uint256 RB_Factor, bool purchasedOrNot);
    event List(uint256 id, string name, string brand, string image, uint256 cost, uint256 RB_Factor, uint256 _quantity, address lister);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address payable _pool, address payable _weth) {
        owner = msg.sender;
        pool = PoolModel2(_pool);
        weth = IWETH(_weth);
    }

    function list(
        uint256 _id,
        string memory _name,
        string memory _brand,
        string memory _image,
        uint256 _cost,
        uint256 _RB_Factor,
        uint256 _quantity
    ) public payable {
        // Create Shoe Item
        Shoe memory shoe = Shoe(
            _id,
            _name,
            _brand,
            _image,
            _cost,
            _RB_Factor,
            _quantity,
            msg.sender
        );

        uint platformFee = (_cost*10)/100; // 10% percent of fee will be transfered to Pool.sol
        require(msg.value>=platformFee,"Please enter valid amount");

        shoes[_id] = shoe;
        emit List(_id, _name, _brand, _image, _cost, _RB_Factor, _quantity, msg.sender);

        weth.deposit{value: platformFee}();
        require(weth.transfer(address(pool), platformFee));
    }

    function buy(uint256 _id) public payable {

        Shoe memory shoe = shoes[_id];
        require(msg.value >= shoe.cost);
        require(shoe.quantity > 0);

    // This Order parameter will track if user wants to purchase more than 1 shoe.
        Order memory order = Order(block.timestamp, shoe);
        orderCount[msg.sender]++; // <-- Order ID
        orders[msg.sender][orderCount[msg.sender]] = order;

        shoes[_id].quantity = shoe.quantity - 1;
        hasUserPurchased_A_Shoe[msg.sender][_id]= true;
        emit Buy(msg.sender, orderCount[msg.sender], shoe.id, shoe.RB_Factor, true);

        (bool success,) = shoe.lister.call{value: msg.value}(""); // Pay to lister of shoe
        require(success);
    }

    // If user has more than 1 shoe, he can choose which shoe he want to earn reward with.
    function selectShoe(uint256 _shoeId) public view returns(Shoe memory){
        require(hasUserPurchased_A_Shoe[msg.sender][_shoeId],"You does not own this shoe");
        Shoe memory shoe = shoes[_shoeId];
        return shoe;
    }

    function hasPurchasedShoe(address _account, uint256 _shoeId) public view returns(bool){
        return hasUserPurchased_A_Shoe[_account][_shoeId];
    }

    // Function to get the purchase timestamp for a specific order
    function getOrderTime(address _account, uint256 _orderId) public view returns (uint256) {
        return orders[_account][_orderId].time;
    }

    // Function to get the RB_Factor of a shoe
    function getShoeRB_Factor(uint256 _shoeId) public view returns (uint256) {
        return shoes[_shoeId].RB_Factor;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
