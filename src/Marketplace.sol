// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import {PoolModel2} from "./PoolModels/PoolModel2.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address s_owner) external view returns (uint);
}

contract MarketPlace {
    address public s_owner;
    PoolModel2 public immutable pool;
    IWETH public immutable weth;

    struct Shoe {
        uint256 id;
        string name;
        string brand;
        string image;
        uint256 cost;
        uint256 RB_Factor;
        uint256 quantity;
        address lister;
    }

    struct Order {
        uint256 time;
        Shoe shoe;
    }

    mapping(uint256 => Shoe) public s_shoes;
    mapping(uint256 => bool) public s_isSoldOut;
    mapping(address => mapping(uint256 => Order)) public s_orders;
    mapping(address => uint256) public s_orderCount;

    mapping(address => mapping(uint256 => uint256)) public s_stepsByUserAtMoment;
    mapping(bytes32 => address) private s_emailToAddress;
    mapping(bytes32 => uint256) private s_emailToSteps;
    mapping(address => mapping(uint256 => bool)) public s_hasUserPurchased_A_Shoe;
    mapping(address => uint256) public s_userSelectedShoe;
    mapping(address => bool) public s_IsUserRegistred;

    mapping(address => bool) public s_IsSellerRegistred;
    mapping(address => uint256) public s_SellerKYC;

    uint256 public s_shoeCount;
    uint[] public s_arrayOfIds;

    mapping(address => uint[]) public s_numberOfShoeIdsOwnerByUser;

    event Buy(
        address buyer,
        uint256 orderId,
        uint256 shoeId,
        uint256 RB_Factor,
        bool purchasedOrNot
    );
    event List(
        uint256 id,
        string name,
        string brand,
        string image,
        uint256 cost,
        uint256 RB_Factor,
        uint256 _quantity,
        address lister
    );
    event EmailToAddressMapped(
        bytes32 indexed emailHash,
        address indexed userAddress
    );
    event EmailToStepsMapped(
        bytes32 indexed emailHash,
        uint256 indexed userAddress
    );

    modifier onlyOwner() {
        require(msg.sender == s_owner, "Not the owner");
        _;
    }

    modifier shoeValidity(uint256 _id) {
        require(!s_isSoldOut[_id], "Shoe sold out");
        _;
    }

    constructor(address payable _pool, address payable _weth) {
        s_owner = msg.sender;
        pool = PoolModel2(_pool);
        weth = IWETH(_weth);
    }

    function chainlinkfunctionData() public {}

    /**
    * @dev Function to map an email to steps covered
    * IMP - THIS FUNCTION WILL BE CALLED WHEN USER FETCHES HIS API DATA.
    */
    function mapEmailToSteps(string calldata _email, uint256 _steps) external {
        bytes32 hashed = _stringToHash(_email);
        require(hashed != 0, "Enter email");
        s_emailToSteps[hashed] = _steps;
        emit EmailToStepsMapped(hashed, _steps);
    }

    /** 
    * @dev Function to map an email to an Ethereum address
    * IMP - THIS FUNCTION WILL BE CALLED AFTER USER HITS THE CONNECT WALLET BUTTON-----//
    */
    function mapEmailToAddress(string calldata _email, address _account) external {
        require(_account != address(0), "Invalid address");
        bytes32 hashed = _stringToHash(_email);
        require(s_emailToAddress[hashed] == address(0), "Email already linked");
        s_emailToAddress[hashed] = _account;
        emit EmailToAddressMapped(hashed, _account);
    }

    function _stringToHash(string memory _string) internal pure returns (bytes32) {
        return keccak256(abi.encode(_string));
    }
    /** 
    * @dev
    * IMP - WHEN USER PURCHASES A SHOE THIS FUNCTION WILL BE CALLED.
    */
    function linkAddressToSteps(string calldata _email, address _account, uint256 _steps) public {
        bytes32 hashed = _stringToHash(_email);
        require(s_emailToAddress[hashed] == _account, "Invalid Data");
        s_stepsByUserAtMoment[_account][block.timestamp] = _steps;
    }

    /** 
    * @dev
    * Lister has to call this function first, before calling List function.
    */
    function SellerRegisteration(uint256 _creditCardNumber) public {
        require(s_IsSellerRegistred[msg.sender]==false,"Seller Already registered");

        s_SellerKYC[msg.sender] = _creditCardNumber;
        s_IsSellerRegistred[msg.sender] = true;
    }

    /** 
    * @dev
    * Function to list the shoes
    */
    function list(
        string memory _name,
        string memory _brand,
        string memory _image,
        uint256 _cost,
        uint256 _RB_Factor,
        uint256 _quantity
    ) public payable {
        require(s_IsSellerRegistred[msg.sender] ==true, "Not registered");
        // Platform Fee is 10% of _cost and 10% of _RB_Factor.
        require(msg.value >= (_cost * 10)/100 + (_RB_Factor*10)/ 100, "Insufficient fee");

        s_shoeCount++;

        s_shoes[s_shoeCount] = Shoe({
            id: s_shoeCount,
            name: _name,
            brand: _brand,
            image: _image,
            cost: _cost,
            RB_Factor: _RB_Factor,
            quantity: _quantity,
            lister: msg.sender
        });
    
        emit List(s_shoeCount, _name, _brand, _image, _cost, _RB_Factor, _quantity, msg.sender);

        uint platformFee = (_cost * 10)/100 + (_RB_Factor * 10) / 100;
        weth.deposit{value: platformFee}();
        require(weth.transfer(address(pool), platformFee), "WETH transfer failed");
    }

    /** 
    * @dev
    * Function to buy the shoes
    */
    function buy(uint256 _id) public payable shoeValidity(_id) {
        Shoe memory shoe = s_shoes[_id];
        require(msg.value >= shoe.cost, "Insufficient payment");
        require(shoe.quantity > 0, "Out of stock");

        s_orderCount[msg.sender]++;
        s_orders[msg.sender][s_orderCount[msg.sender]] = Order(block.timestamp, shoe);

        s_shoes[_id].quantity--;
        s_hasUserPurchased_A_Shoe[msg.sender][_id] = true;
        s_IsUserRegistred[msg.sender] = true;
        if (s_shoes[_id].quantity == 0) {
            s_isSoldOut[_id] = true;
        }

        s_numberOfShoeIdsOwnerByUser[msg.sender].push(_id);

        emit Buy(msg.sender, s_orderCount[msg.sender], shoe.id, shoe.RB_Factor, true);

        (bool success, ) = shoe.lister.call{value: msg.value}("");
        require(success, "Payment to lister failed");
    }

    function selectShoe(uint256 _id) public returns(uint256){
        require(s_hasUserPurchased_A_Shoe[msg.sender][_id], "You don't own this shoe");
        s_userSelectedShoe[msg.sender]= _id;
        return _id;
    }

    //------------------------------VIEW FUNCTIONS-----------------------------------------
    //-------------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------------

    function getShoeIdsOwnedByUser(address _user) public view returns (uint256[] memory) {
        return s_numberOfShoeIdsOwnerByUser[_user];
    }   

    function getListedShoeById(uint256 _id) public view returns (Shoe memory){
        Shoe memory shoe = s_shoes[_id];
        return shoe;
    }

    function getTotalNumberOfListedShoe() public view returns (uint256){
        return s_shoeCount;
    }

    function KYCdetailsOfLister(address _account) public view returns (uint256){
        return s_SellerKYC[_account];
    }

    /**
    * @dev
    * IGNORE-- this function for now
    * When User has two more than one shoe to choose.
    */
    // function selectShoe(uint256 _shoeId) public view returns (Shoe memory) {
    //     require(s_hasUserPurchased_A_Shoe[msg.sender][_shoeId], "You do not own this shoe");
    //     return s_shoes[_shoeId];
    // }

    function hasPurchasedShoe(address _account, uint256 _shoeId) public view returns (bool) {
        return s_hasUserPurchased_A_Shoe[_account][_shoeId];
    }

    function getOrderTime(address _account, uint256 _orderId) public view returns (uint256) {
        return s_orders[_account][_orderId].time;
    }

    function getShoeRB_Factor(uint256 _shoeId) public view returns (uint256) {
        return s_shoes[_shoeId].RB_Factor;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getAddress(string calldata email) external view returns (address) {
        return s_emailToAddress[_stringToHash(email)];
    }
}

// pragma solidity ^0.8.9;

// import {PoolModel2} from "./PoolModels/PoolModel2.sol";

// interface IWETH {
//     function deposit() external payable;

//     function transfer(address to, uint value) external returns (bool);

//     function balanceOf(address s_owner) external view returns (uint);
// }

// contract MarketPlace {
//     address public s_owner;
//     PoolModel2 public pool;
//     IWETH public weth;

//     struct Shoe {
//         uint256 id;
//         string name;
//         string brand;
//         string image;
//         uint256 cost;
//         uint256 RB_Factor;
//         uint256 quantity; // let's keep it one
//         address lister;
//     }

//     struct Order {
//         uint256 time;
//         Shoe shoe;
//     }

//     mapping(uint256 => Shoe) public s_shoes;
//     mapping(uint256 => bool) public s_isSoldOut;
//     mapping(address => mapping(uint256 => Order)) public s_orders;
//     mapping(address => uint256) public s_orderCount;

//     // user => timestamp => number of steps
//     mapping(address => mapping(uint256 => uint256))
//         public s_stepsByUserAtMoment;

//     mapping(bytes32 => address) private s_emailToAddress;
//     mapping(bytes32 => uint256) private s_emailToSteps;
//     mapping(address => mapping(uint256 => bool))
//         public s_hasUserPurchased_A_Shoe;

//     event Buy(
//         address buyer,
//         uint256 orderId,
//         uint256 shoeId,
//         uint256 RB_Factor,
//         bool purchasedOrNot
//     );
//     event List(
//         uint256 id,
//         string name,
//         string brand,
//         string image,
//         uint256 cost,
//         uint256 RB_Factor,
//         uint256 _quantity,
//         address lister
//     );
//     event EmailToAddressMapped(
//         bytes32 indexed emailHash,
//         address indexed userAddress
//     );
//     event EmailToStepsMapped(
//         bytes32 indexed emailHash,
//         uint256 indexed userAddress
//     );

//     modifier onlyOwner() {
//         require(msg.sender == s_owner);
//         _;
//     }

//     modifier shoeValidity(uint256 _id) {
//         require(!s_isSoldOut[_id]);
//         _;
//     }

//     constructor(address payable _pool, address payable _weth) {
//         s_owner = msg.sender;
//         pool = PoolModel2(_pool);
//         weth = IWETH(_weth);
//     }

//     // Related to chainlink functions and frrontend interactions
//     function chainlinkfunctionData() public {}

//     // Function to map an email to an steps covered
//     // **IMP - THIS FUNCTION WILL BE CALLED WHEN USER FETCHES HIS API DATA.
//     function mapEmailToSteps(string calldata _email, uint256 _steps) external {
//         bytes32 hashed = _stringToHash(_email);
//         require(hashed != 0, "Enter eemail");
//         s_emailToSteps[hashed] = _steps;
//         emit EmailToStepsMapped(hashed, _steps);
//     }

//     // Function to map an email to an Ethereum address
//     // **IMP - THIS FUNCTION WILL BE CALLED AFTER USER HITS THE CONNECT WALLET BUTTON-----//
//     function mapEmailToAddress(
//         string calldata _email,
//         address _account
//     ) external {
//         require(_account != address(0), "Invalid address");
//         bytes32 hashed = _stringToHash(_email);

//         require(
//             s_emailToAddress[hashed] == address(0),
//             "Email already linked with an account"
//         );
//         s_emailToAddress[hashed] = _account;
//         emit EmailToAddressMapped(hashed, _account);
//     }

//     function _stringToHash(
//         string memory _string
//     ) internal pure returns (bytes32) {
//         return keccak256(abi.encode(_string));
//     }

//     // **IMP - WHEN USER PURCHASES A SHOE THIS FUNCTION WILL BE CALLED.
//     function linkAddressToSteps(
//         string calldata _email,
//         address _account
//     ) public {
//         bytes32 hashed = _stringToHash(_email);
//         require(s_emailToAddress[hashed] == _account, "Invalid Data");
//         s_stepsByUserAtMoment[_account][block.timestamp] = s_emailToSteps[
//             hashed
//         ];
//     }

//     //Called By User
//     function list(
//         uint256 _id,
//         string memory _name,
//         string memory _brand,
//         string memory _image,
//         uint256 _cost,
//         uint256 _RB_Factor,
//         uint256 _quantity
//     ) public payable {
//         // Create Shoe Item
//         Shoe memory shoe = Shoe(
//             _id,
//             _name,
//             _brand,
//             _image,
//             _cost,
//             _RB_Factor,
//             _quantity,
//             msg.sender
//         );

//         uint platformFee = (_cost * 10) / 100; // 10% percent of fee will be transfered to Pool.sol
//         require(msg.value >= platformFee, "Please enter valid amount");

//         s_shoes[_id] = shoe;
//         emit List(
//             _id,
//             _name,
//             _brand,
//             _image,
//             _cost,
//             _RB_Factor,
//             _quantity,
//             msg.sender
//         );

//         weth.deposit{value: platformFee}();
//         require(weth.transfer(address(pool), platformFee));
//     }

//     //Called By User
//     function buy(uint256 _id) public payable shoeValidity(_id) {
//         Shoe memory shoe = s_shoes[_id];
//         require(msg.value >= shoe.cost);
//         require(shoe.quantity > 0);

//         // This Order parameter will track if user wants to purchase more than 1 shoe.
//         Order memory order = Order(block.timestamp, shoe);
//         s_orderCount[msg.sender]++; // <-- Order ID
//         s_orders[msg.sender][s_orderCount[msg.sender]] = order;

//         s_shoes[_id].quantity = shoe.quantity - 1;
//         s_hasUserPurchased_A_Shoe[msg.sender][_id] = true;
//         s_isSoldOut[_id] = true;
//         emit Buy(
//             msg.sender,
//             s_orderCount[msg.sender],
//             shoe.id,
//             shoe.RB_Factor,
//             true
//         );

//         (bool success, ) = shoe.lister.call{value: msg.value}(""); // Pay to lister of shoe
//         require(success);
//     }

//     // Ignore this for now
//     // If user has more than 1 shoe, he can choose which shoe he want to earn reward with.
//     function selectShoe(uint256 _shoeId) public view returns (Shoe memory) {
//         require(
//             s_hasUserPurchased_A_Shoe[msg.sender][_shoeId],
//             "You does not own this shoe"
//         );
//         Shoe memory shoe = s_shoes[_shoeId];
//         return shoe;
//     }

//     function hasPurchasedShoe(
//         address _account,
//         uint256 _shoeId
//     ) public view returns (bool) {
//         return s_hasUserPurchased_A_Shoe[_account][_shoeId];
//     }

//     // Function to get the purchase timestamp for a specific order
//     function getOrderTime(
//         address _account,
//         uint256 _orderId
//     ) public view returns (uint256) {
//         return s_orders[_account][_orderId].time;
//     }

//     // Function to get the RB_Factor of a shoe
//     function getShoeRB_Factor(uint256 _shoeId) public view returns (uint256) {
//         return s_shoes[_shoeId].RB_Factor;
//     }

//     function getBalance() public view returns (uint256) {
//         return address(this).balance;
//     }

//     // Function to get the address associated with an email
//     function getAddress(string calldata email) external view returns (address) {
//         bytes32 emailHash = keccak256(abi.encode(email));
//         return s_emailToAddress[emailHash];
//     }
// }
