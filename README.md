# RunBro: Decentralized Fitness Marketplace

RunBro is a decentralized platform that rewards users for their physical activity by integrating the Google Fit API with a unique reward model. Users can buy and sell fitness-related items (such as shoes) while earning native tokens (RBT) based on their steps.

## Team

Our team is composed of passionate individuals dedicated to making RunBro a success. If you have any questions or would like to contribute to the project, please feel free to reach out.

### Core Contributors
- **Shubham** - *Smart Contracts* - [github://orangesantra](https://github.com/orangesantra)
- **Jaka** - *Front-End* - [github://BChainbuddy](https://github.com/BChainbuddy)
- **Charles** - *Project Manager* - [github://SupaMega24](https://github.com/SupaMega24)
- **Susan** - *Marketing/Design* - [github://2RowFlow](https://github.com/2RowFlow)


## Contract Architecture

![image](https://github.com/ChainlinkHackaton/SmartContracts/assets/138974329/5b32ca5e-6dfe-4e22-b6d6-1f6b277f2b41)

### 1. Marketplace.sol

- Responsible for listing and buying shoes.
- **Seller**: Lists shoes by specifying price, RB Factor, brand name, and shoe name.
- **Buyer**: Purchases shoes and becomes eligible to receive RB Tokens.

### 2. RunBroToken.sol (RBT)

- The native token of the platform.
- Rewards are based on the reward model and protocol architecture.

### 3. Pool.sol

- Determines the value of RB Tokens.
- The pool contains two tokens: WETH (wrapped Ether) and RB Tokens.
- Follows the CPAMM (Constant Product Automated Market Maker) strategy.

#### How WETH is Supplied?

- WETH is supplied from the platform fee charged when a seller lists a shoe.

#### How RBT is Supplied?

- RBT is minted based on the amount of WETH in the pool.
- If the WETH amount increases, RBT is minted to maintain price stability (TOLERANCE_FACTOR).

### 4. Reward.sol

- Defines the reward strategy for distributing RBT to users based on their steps.

#### How RBT Amount is Determined?

- The amount of RBT distributed is calculated using a formula (not specified here).

## Chainlink Integration

### Chainlink Functions

- Chainlink functions fetch data from the Google Fit API to retrieve step counts.
https://functions.chain.link/

### Chainlink Automation

- Chainlink is used to add liquidity to Pool.sol every 24 hours, normalizing the WETH-to-RBT ratio.
https://automation.chain.link/

## User Flow

1. A seller lists a shoe, paying the platform fee.
2. The shoe appears on the marketplace with its price, RB Factor, brand name, and shoe name.
3. A buyer purchases the shoe, paying the price to the seller.
4. The buyer becomes eligible to claim rewards based on their steps.
5. After a specified duration (D), the user can calculate and claim their reward based on their steps and the total steps recorded by all users during D.

## Incentives

- **Buyer**: Earns rewards based on their steps when buying from the RunBro platform.
- **Seller**: Shoes sell quickly on RunBro, and sellers don't need to offer high discounts since buyers control their profit/loss based on steps.

---

## Tech Stack

### JavaScript
- **Frontend**: Our user interface is built using Next.js, a React framework that enables server-side rendering and generating static websites for React-based web applications.
- **Styling**: We use Tailwind CSS for styling, which provides a utility-first approach to design our components efficiently.

### Solidity
- **Smart Contracts**: Our core blockchain functionality is powered by Solidity, the contract-oriented programming language for writing smart contracts on various blockchain platforms.
- **MarketPlace.sol**: This contract handles the listing and purchasing of shoes on our platform.
- **RunBroToken.sol**: Manages the RBT token transactions and balances.
- **Reward.sol**: Calculates rewards for various activities, including purchasing shoes, walking, and affiliate marketing.

### Foundry
- **Testing**: We use Foundry, a blazing fast, portable, and modular toolkit for Ethereum application development, to test our smart contracts ensuring security and reliability.
  
## Contributing

We welcome contributions from the community.

1.	Fork the repository.
2.	Create a new branch: git checkout -b feature/my-feature.
3.	Commit your changes: git commit -am 'Add my feature'.
4.	Push to the branch: git push origin feature/my-feature.
5.	Submit a pull request.

## License
RunBro is released under the MIT License. See the LICENSE file for more details.








