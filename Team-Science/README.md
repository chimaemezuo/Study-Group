# Decentralized Think Tank Smart Contract

A comprehensive blockchain-based platform for collaborative research, governance, and knowledge sharing built on the Stacks blockchain using Clarity smart contract language.

## Overview

The Decentralized Think Tank is a democratic platform that enables researchers, academics, and thought leaders to collaborate on research projects, propose initiatives, conduct peer reviews, and participate in decentralized governance. Members stake STX tokens to join and earn reputation through active participation.

## Features

### Core Functionality
- **Membership System**: Stake-based membership with reputation tracking
- **Proposal Governance**: Democratic voting on funding requests and initiatives
- **Research Publications**: Submit and peer-review academic papers
- **Collaboration Management**: Create and manage research collaborations
- **Treasury Management**: Community-controlled funding allocation

### Key Components
- Weighted voting based on stake and reputation
- Peer review system for research quality assurance
- IPFS integration for decentralized document storage
- Reputation-based incentive mechanisms
- Platform fee collection for sustainability

## Contract Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `MIN-STAKE` | 1,000,000 | Minimum STX (1 STX) required to join |
| `PROPOSAL-COST` | 500,000 | Cost in STX (0.5 STX) to create a proposal |
| `MAX-PROPOSAL-DURATION` | 10,080 | Maximum voting duration (1 week in blocks) |
| `MIN-PROPOSAL-DURATION` | 144 | Minimum voting duration (1 day in blocks) |
| `REPUTATION-DECAY-FACTOR` | 95 | Reputation decay percentage (5% per period) |

## Data Structures

### Members
- Address and stake information
- Reputation score and activity metrics
- Join date and active status
- Contribution statistics

### Proposals
- Title, description, and funding details
- Voting parameters and results
- Status tracking and categorization
- Creator and timing information

### Research Papers
- Title, abstract, and IPFS hash
- Author and co-author information
- Peer review metrics and ratings
- Publication details and access settings

### Collaborations
- Project information and membership
- Leadership and participant tracking
- Timeline and status management

## Main Functions

### Membership Functions

#### `join-think-tank`
```clarity
(join-think-tank (stake-amount uint))
```
Join the think tank by staking the minimum required STX tokens.
- **Parameters**: Amount of STX to stake (must be >= MIN-STAKE)
- **Returns**: Member ID on success
- **Requirements**: Must not already be a member

#### `increase-stake`
```clarity
(increase-stake (additional-amount uint))
```
Increase your stake to gain more voting power.
- **Parameters**: Additional STX amount to stake
- **Returns**: New total stake amount
- **Requirements**: Must be an existing member

### Proposal Functions

#### `create-proposal`
```clarity
(create-proposal title description funding-requested duration category)
```
Create a new proposal for community voting.
- **Parameters**: 
  - `title`: Proposal title (max 100 chars)
  - `description`: Detailed description (max 500 chars)
  - `funding-requested`: STX amount requested from treasury
  - `duration`: Voting duration in blocks
  - `category`: Proposal category (max 50 chars)
- **Cost**: 0.5 STX proposal fee
- **Returns**: Proposal ID on success

#### `vote-on-proposal`
```clarity
(vote-on-proposal proposal-id vote-yes)
```
Vote on an active proposal.
- **Parameters**:
  - `proposal-id`: ID of the proposal to vote on
  - `vote-yes`: Boolean (true for yes, false for no)
- **Returns**: Success confirmation
- **Vote Weight**: Based on stake and reputation

#### `finalize-proposal`
```clarity
(finalize-proposal proposal-id)
```
Finalize voting and execute approved proposals.
- **Parameters**: Proposal ID to finalize
- **Approval Threshold**: 60% of total votes
- **Effect**: Transfers funds if proposal passes and requests funding

### Research Functions

#### `submit-research-paper`
```clarity
(submit-research-paper title abstract co-authors ipfs-hash category is-open-access)
```
Submit a research paper for publication and peer review.
- **Parameters**:
  - `title`: Paper title (max 100 chars)
  - `abstract`: Paper abstract (max 1000 chars)
  - `co-authors`: List of co-author member IDs (max 10)
  - `ipfs-hash`: IPFS hash for paper storage (max 100 chars)
  - `category`: Research category (max 50 chars)
  - `is-open-access`: Boolean for access type
- **Reputation Reward**: +25 reputation points
- **Returns**: Research paper ID

#### `submit-peer-review`
```clarity
(submit-peer-review research-id rating review-hash)
```
Submit a peer review for a research paper.
- **Parameters**:
  - `research-id`: ID of paper to review
  - `rating`: Rating from 1-10
  - `review-hash`: IPFS hash of review content
- **Reputation Reward**: +15 reputation points
- **Restrictions**: Cannot review own papers

### Collaboration Functions

#### `create-collaboration`
```clarity
(create-collaboration title description initial-members)
```
Create a new research collaboration project.
- **Parameters**:
  - `title`: Collaboration title (max 100 chars)
  - `description`: Project description (max 500 chars)
  - `initial-members`: List of initial member IDs (max 20)
- **Returns**: Collaboration ID

### Treasury Functions

#### `fund-treasury`
```clarity
(fund-treasury)
```
Contribute STX tokens to the platform treasury.
- **Effect**: Transfers caller's STX balance to treasury
- **Returns**: Amount transferred

## Read-Only Functions

### Information Retrieval
- `get-member-info`: Retrieve member details by ID
- `get-member-by-principal`: Get member info by Stacks address
- `get-proposal`: Retrieve proposal details
- `get-research-paper`: Get research paper information
- `get-collaboration`: Retrieve collaboration details
- `get-vote`: Check voting record for specific proposal/member
- `get-peer-review`: Get peer review details
- `get-treasury-balance`: Check current treasury balance
- `get-platform-stats`: Get overall platform statistics
- `is-member`: Check if address is a registered member

## Voting Mechanism

### Vote Weight Calculation
Vote weight is calculated using the formula:
```
Vote Weight = (Stake / 100,000) + (Reputation / 10)
```

This ensures both financial commitment (stake) and community contribution (reputation) influence voting power.

### Approval Process
1. Proposals require 60% approval to pass
2. Voting period must be between 1 day and 1 week
3. Only active members can vote
4. Each member can vote once per proposal
5. Votes are weighted by stake and reputation

## Reputation System

### Earning Reputation
- Join think tank: +100 (starting reputation)
- Create proposal: +10 points
- Vote on proposal: +5 points
- Submit research paper: +25 points
- Submit peer review: +15 points

### Reputation Decay
- 5% decay per period (configurable)
- Encourages ongoing participation
- Prevents inactive members from maintaining high influence

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | ERR-OWNER-ONLY | Function restricted to contract owner |
| u101 | ERR-NOT-FOUND | Requested item not found |
| u102 | ERR-ALREADY-EXISTS | Item already exists |
| u103 | ERR-INSUFFICIENT-STAKE | Stake amount too low |
| u104 | ERR-VOTING-ENDED | Voting period has ended |
| u105 | ERR-ALREADY-VOTED | Member has already voted |
| u106 | ERR-NOT-MEMBER | Address is not a registered member |
| u107 | ERR-INVALID-DURATION | Proposal duration outside valid range |
| u108 | ERR-PROPOSAL-NOT-ACTIVE | Proposal is not in active status |
| u109 | ERR-INSUFFICIENT-FUNDS | Treasury has insufficient funds |
| u110 | ERR-ALREADY-MEMBER | Address is already a member |
| u111 | ERR-INVALID-REPUTATION | Rating outside valid range (1-10) |

## Integration Requirements

### IPFS Integration
The contract references IPFS hashes for:
- Research paper storage
- Peer review content
- Supplementary documentation

### Frontend Integration
Web applications should implement:
- Stacks wallet connection
- STX token handling
- IPFS content retrieval
- Member dashboard
- Voting interface
- Research submission forms

## Deployment

### Prerequisites
- Stacks blockchain testnet/mainnet access
- Clarity development environment
- Sufficient STX for deployment transaction

### Deployment Steps
1. Compile the Clarity contract
2. Deploy to Stacks blockchain
3. Verify contract deployment
4. Initialize with initial parameters if needed

## Usage Examples

### Joining the Think Tank
```javascript
// Using @stacks/transactions
const joinTx = await makeContractCall({
  contractAddress: 'CONTRACT_ADDRESS',
  contractName: 'think-tank',
  functionName: 'join-think-tank',
  functionArgs: [uintCV(1000000)], // 1 STX
  senderKey: 'PRIVATE_KEY'
});
```

### Creating a Proposal
```javascript
const proposalTx = await makeContractCall({
  contractAddress: 'CONTRACT_ADDRESS',
  contractName: 'think-tank',
  functionName: 'create-proposal',
  functionArgs: [
    stringAsciiCV('Research Funding'),
    stringAsciiCV('Funding for climate change research'),
    uintCV(5000000), // 5 STX requested
    uintCV(1440), // 10 days voting period
    stringAsciiCV('Climate Science')
  ],
  senderKey: 'PRIVATE_KEY'
});
```

## Security Considerations

### Access Controls
- Member-only functions check membership status
- Owner-only functions restricted to contract deployer
- Proposal creation requires fee payment
- Voting restricted to proposal duration

### Economic Security
- Minimum stake requirements prevent spam
- Proposal fees discourage frivolous submissions
- Reputation decay encourages continued participation
- Weighted voting prevents simple majority attacks

## Governance

### Platform Parameters
The contract owner can modify:
- Platform fee percentage
- Other administrative parameters as needed

### Community Governance
- All funding decisions made by member voting
- Research quality maintained through peer review
- Collaboration management decentralized to members