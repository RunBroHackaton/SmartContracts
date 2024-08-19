// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
// import {PoolModel2} from "./PoolModels/PoolModel2.sol";
import {WethRegistry} from "./PoolModels/WethRegistry.sol";
import {Escrow} from "./Escrow.sol";
import {RunBroToken} from "./RunBroToken.sol";
import {KYC} from "./DAO-KYC.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address s_owner) external view returns (uint);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract MarketPlace {
    address public s_owner;

    IWETH public immutable weth;
    WethRegistry public immutable wethregistry;
    Escrow public immutable escrow;
    RunBroToken public immutable runbroToken;
    KYC public immutable kyc;

    struct Shoe {
        uint256 id;
        string name;
        string brand;
        string image;
        uint256 cost;
        uint256 RB_Factor;
        uint256 quantity;
        address lister;
        bool payedToEscrow;
        bool payedToSeller;
        bool confirmationByBuyer;
        bool confirmationBySeller;
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
    mapping(address => mapping(uint256 => bool)) public s_userInitiatedPurchase;
    mapping(address => uint256) public s_userSelectedShoe;
    mapping(address => bool) public s_IsUserRegistred;

    uint256 public s_shoeCount;

    mapping(address => uint[]) public s_numberOfShoeIdsOwnerByUser;

    // Slot consideration
    mapping(address => uint256) public s_userInSlot;
    // Home Address
    mapping(address => string) public s_userHomeAddress;

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

    constructor(address _wethRegistry, address _weth, address payable _escrow, address _runbroToken, address _kyc) {
        s_owner = msg.sender;
        weth = IWETH(_weth);
        wethregistry = WethRegistry(_wethRegistry);
        escrow = Escrow(_escrow);
        runbroToken = RunBroToken(_runbroToken);
        kyc = KYC(_kyc);
    }

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
    * Function to list the shoe, seller/company can only list if they are KYC verified.
    */
    function list(
        string memory _name,
        string memory _brand,
        string memory _image,
        uint256 _cost,
        uint256 _RB_Factor,
        uint256 _quantity
    ) public payable {
        // Platform Fee is 10% of _cost and 10% of _RB_Factor.
        require(kyc.checkIfSellerIsRegisteredOrNot(msg.sender), "KYC-Unverified");
        require(msg.value >= (_cost * 10)/100 + (_RB_Factor * 10)/100, "Insufficient fee");

        s_shoeCount++;

        s_shoes[s_shoeCount] = Shoe({
            id: s_shoeCount,
            name: _name,
            brand: _brand,
            image: _image,
            cost: _cost,
            RB_Factor: _RB_Factor,
            quantity: _quantity,
            lister: msg.sender,
            payedToEscrow: false,
            payedToSeller: false,
            confirmationByBuyer: false,
            confirmationBySeller: false
        });
    
        emit List(s_shoeCount, _name, _brand, _image, _cost, _RB_Factor, _quantity, msg.sender);

        uint platformFee = (_cost * 10)/100 + (_RB_Factor * 10)/100;
        weth.deposit{value: platformFee}();
        weth.transfer(address(wethregistry), platformFee);
    
        wethregistry._updateReserveBalance(platformFee);
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
        s_userInitiatedPurchase[msg.sender][_id] = true;
        s_IsUserRegistred[msg.sender] = true;
        if (s_shoes[_id].quantity == 0) {
            s_isSoldOut[_id] = true;
        }
        
        s_numberOfShoeIdsOwnerByUser[msg.sender].push(_id);

        uint256 currentSlot = wethregistry.s_currentNumberOfSlots();
        wethregistry._addUserToSlot(currentSlot, msg.sender);

        //--------------Escrow----------------
        s_shoes[_id].payedToEscrow = true;
        (bool success, ) = address(escrow).call{value: msg.value}("");
        require(success, "Payment to Escrow failed");
        escrow.updateBuyerPayment(msg.sender, s_shoes[_id].lister, msg.value);

        emit Buy(msg.sender, s_orderCount[msg.sender], shoe.id, shoe.RB_Factor, true);    
    }

    /**
    @dev This function will be called by user, when he have atleast puchased 3 shoes.
     */
    function claimrbtokens() public {
        require(s_numberOfShoeIdsOwnerByUser[msg.sender].length >=3, "You haven't purchased 3 shoes yet!");
        runbroToken.mint(msg.sender, 1*10**18);
    }
    /**
    @dev The purpose of this function, to set the Home Address for shipping purpose.
     */
    function setUserHomeAddress(string memory _homeAddress) public {
        s_userHomeAddress[msg.sender] = _homeAddress;
    }
    /**
    @dev The purpose of this function, to confirm from buyer side that shoe has been deliverd.
     */
    function confirmDeliveryOfShoeByUser(uint256 _orderId) public {
        require(s_userInitiatedPurchase[msg.sender][_orderId], "You don't own this shoe");
        require(s_shoes[_orderId].confirmationByBuyer == false, "Shoe already delivered");

        s_shoes[_orderId].confirmationByBuyer = true;
    }
    /**
    @dev The purpose of this function, to confirm from seller side that shoe has been deliverd.
     * once this function is executed, the funds will be transfered to seller from escrow.
     */
    function confirmDeliveryOfShoeBySeller(uint256 _orderId) public {
        require(s_shoes[_orderId].payedToSeller == false, "Payment already done");
        require(s_shoes[_orderId].confirmationBySeller == false, "Shoe already delivered");
        require(s_shoes[_orderId].confirmationByBuyer == true, "Buyer has not confirmed yet");
        require(s_shoes[_orderId].lister == msg.sender, "Payment to escrow not done");

        s_shoes[_orderId].confirmationBySeller = true;
        escrow.payToSeller(s_shoes[_orderId].lister);
        s_shoes[_orderId].payedToSeller = true;
    }

    /**
    @dev A user can have multiple shoes, through this function he/she will be able to decide
     * which selecte shoe he/she want's to move on with.
     * it will return the shoeId.
     */
    function selectShoe(uint256 _id) public returns(uint256){
        require(s_userInitiatedPurchase[msg.sender][_id], "You don't own this shoe");
        s_userSelectedShoe[msg.sender]= _id;
        return _id;
    }

    //------------------------------VIEW FUNCTIONS-----------------------------------------
    //-------------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------------
    function getUserHomeAddress(address _account) public view returns(string memory){
        return s_userHomeAddress[_account];
    }
    
    function getSlotIdOfUser(address _account) public view returns (uint256) {
        return s_userInSlot[_account];
    } 

    function checkUserRegistraction(address _user) public view returns (bool) {
        return s_IsUserRegistred[_user];
    }

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

    /**
    * @dev
    * IGNORE-- this function for now
    * When User has two more than one shoe to choose.
    */
    // function selectShoe(uint256 _shoeId) public view returns (Shoe memory) {
    //     require(s_userInitiatedPurchase[msg.sender][_shoeId], "You do not own this shoe");
    //     return s_shoes[_shoeId];
    // }

    function hasPurchasedShoe(address _account, uint256 _shoeId) public view returns (bool) {
        return s_userInitiatedPurchase[_account][_shoeId];
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
