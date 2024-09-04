interface MarketPlace {
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

    event Buy(address buyer, uint256 orderId, uint256 shoeId, uint256 RB_Factor, bool purchasedOrNot);
    event EmailToAddressMapped(bytes32 indexed emailHash, address indexed userAddress);
    event EmailToStepsMapped(bytes32 indexed emailHash, uint256 indexed userAddress);
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

    function buy(uint256 _id) external payable;
    function chainlinkfunctionData() external;
    function getAddress(string memory email) external view returns (address);
    function getBalance() external view returns (uint256);
    function getOrderTime(address _account, uint256 _orderId) external view returns (uint256);
    function getShoeRB_Factor(uint256 _shoeId) external view returns (uint256);
    function hasPurchasedShoe(address _account, uint256 _shoeId) external view returns (bool);
    function linkAddressToSteps(string memory _email, address _account, uint256 _steps) external;
    function list(
        uint256 _id,
        string memory _name,
        string memory _brand,
        string memory _image,
        uint256 _cost,
        uint256 _RB_Factor,
        uint256 _quantity
    ) external payable;
    function mapEmailToAddress(string memory _email, address _account) external;
    function mapEmailToSteps(string memory _email, uint256 _steps) external;
    function pool() external view returns (address);
    function s_IsUserRegistred(address) external view returns (bool);
    function s_hasUserPurchased_A_Shoe(address, uint256) external view returns (bool);
    function s_isSoldOut(uint256) external view returns (bool);
    function s_orderCount(address) external view returns (uint256);
    function s_orders(address, uint256) external view returns (uint256 time, Shoe memory shoe);
    function s_owner() external view returns (address);
    function s_shoes(uint256)
        external
        view
        returns (
            uint256 id,
            string memory name,
            string memory brand,
            string memory image,
            uint256 cost,
            uint256 RB_Factor,
            uint256 quantity,
            address lister
        );
    function s_stepsByUserAtMoment(address, uint256) external view returns (uint256);
    function selectShoe(uint256 _shoeId) external view returns (Shoe memory);
    function weth() external view returns (address);
}

