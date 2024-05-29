// -----------------------------------------Not In Use--------------------------------------------------------

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Reward{
    IERC20 public immutable rewardsToken;
    uint256 public constant MAX_SUPPLY = 1000000 * 10**18; // 1 million tokens
    uint256 public totalMinted = 0;
    uint256 public monthlyMintAmount = 10000 * 10**18; // Example: 10,000 tokens per month
    uint256 public lastMintTime;
    uint256 public totalSteps; // will come from other contract
    uint256 public totalStepsInOneMonth; // will come from other contract
    uint256 public totalNumberOfRegisteredUsers; // will come from other contract


    mapping (address => uint256) public userStepsInOneMonth;
    mapping (address => bool) public isUservalid;
    mapping (address => mapping (uint256 => uint8)) public RB_Factor_Of_ShoeIdOwnedByUser;// will come from other contract
    mapping (address => bool) public hasUserClaimedReward;

    constructor(address _rewardToken){
        lastMintTime = block.timestamp;
        rewardsToken = IERC20(_rewardToken);
    }

    modifier userValidity(){
        isUservalid[msg.sender]=true;
        _;
    }

    function mintMonthlyTokens() external {
        require(block.timestamp >= lastMintTime + 30 days, "Minting too soon");
        require(totalMinted + monthlyMintAmount <= MAX_SUPPLY, "Exceeds maximum supply");
        lastMintTime = block.timestamp;
        totalMinted += monthlyMintAmount;
        rewardsToken.mint(address(this), monthlyMintAmount);
    }

    function calculateReward(address _account, uint256 _shoeId) public view returns(uint256){
        /* @dev  
         formula
         rewardOfUser = (((stepsByUserInOneMonth/totalStepsInOneMonthByAllUsers)*RB_FactorOfShoesOwnedByuser))*totalNumberOfRBTokensInOneMonth)
        */
        require(userStepsInOneMonth[_account]>1000,"Bro cover atlest 1000 steps!");
        require(totalStepsInPeriod()>10_000,"Let other people run");
        require(isUservalid[_account], "User not valid");

        uint256 rewardOfUser = ((userStepsInOneMonth[_account]/totalStepsInPeriod())*10_000)
                               *RB_Factor_Of_ShoeIdOwnedByUser[_account][_shoeId];
        return rewardOfUser;
    }

    function claimReward_ByEntering_ShoeId(uint256 _shoeId) public {
        /* @dev
         Now user can call this function to get the rewards
        */
        require(hasUserClaimedReward[msg.sender], "You already claimed");
        require(isUservalid[msg.sender], "User not valid");

        rewardsToken.transfer(msg.sender, calculateReward(msg.sender, _shoeId));
    }
 
    function addSteps(address user, uint256 stepCount) external {
        uint256 reward = (monthlyMintAmount * stepCount) / totalStepsInPeriod();
        require(rewardsToken.balanceOf(address(this)) >= reward, "Insufficient reward tokens");
        rewardsToken.transferFrom(address(this), user, reward);
    }

    function totalStepsInPeriodByUser() public returns (uint256){

    }

    function totalStepsInPeriod() internal pure returns (uint256) {
        // Implement logic to calculate total steps taken by all users in the period
        return 100000; // Placeholder value
    }


}

    interface IERC20 {
        function totalSupply() external view returns (uint);

        function balanceOf(address account) external view returns (uint);

        function transfer(address recipient, uint amount) external returns (bool);

        function allowance(address owner, address spender) external view returns (uint);

        function approve(address spender, uint amount) external returns (bool);

        function mint(address recipient, uint amount) external;

        function transferFrom(
            address sender,
            address recipient,
            uint amount
        ) external returns (bool);

        event Transfer(address indexed from, address indexed to, uint value);
        event Approval(address indexed owner, address indexed spender, uint value);
    }
