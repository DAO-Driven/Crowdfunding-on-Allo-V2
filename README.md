# A DAO-Driven Crowdfunding Platform on Allo V2

## Introduction

Welcome to Decentralized GrantStream, an innovative crowdfunding platform in the Web3 space, designed to bridge the gap between developers and investors. Leveraging the power of Arbitrum, Allo, and Hats protocols, our platform offers a transparent, democratic process for project funding and management.

## Key Features

### 1. **Proposal Submission by Developers**
   Developers can propose their projects, outlining their goals and the required funding.

### 2. **Investor Participation**
   Investors have the flexibility to browse and fund projects of their choice. They can revoke their funding if they change their mind.

### 3. **Formation of Funding Committee**
   Post full funding, a 'Funding Committee' is formed from all investors, granting them voting power proportional to their investment.

### 4. **Milestone-Based Planning and Voting**
   Developers present a plan with milestones, including fund distribution for each. These milestones are subject to committee voting.

### 5. **Milestone Submission and Approval Process**
   Developers submit completed milestones for committee review. Approval or rejection is based on majority votes.

### 6. **Fund Reclamation Option**
   In case of no progress, the committee can vote to retract funding, redistributing it back to its members.

### 7. **Post-Launch Reward Distribution**
   Successful projects may return rewards to the committee, distributed among investors based on initial contributions.

## Operational Flow

- Developers present projects and request funding.
- Investors fund projects and gain voting rights in the committee.
- The committee oversees fund distribution based on milestone completion.
- Developers can resubmit rejected milestones for new voting rounds.
- A mechanism for fund retraction ensures investor protection.
- Post-launch, rewards can be distributed to investors.

## Vision and Impact

Decentralized GrantStream aims to create a transparent, accountable, and mutually beneficial ecosystem for developers and investors in the decentralized world. It's more than just a funding platform; it's a community where every member plays an active role in shaping the future of innovative projects.

---

## Contracts Overview

### Manager Contract

The Manager contract handles project registration, funding, supplier management, and integrates with the Allo and Hats protocols for seamless fund distribution and management.

### Strategy Contract

The Executor Supplier Voting Strategy contract is the backbone of the Decentralized GrantStream platform is a crucial component that manages the allocation and distribution of funds to recipients based on milestone achievements. It ensures that the funding process is democratic, transparent, and aligned with the investors' interests.

The Executor Supplier Voting Strategy contract is essentially a reimagined version of the Allo-V2's DirectGrantsSimpleStrategy. This original strategy from Allo-V2 was taken as the foundational blueprint, upon which our customized strategy was developed and tailored to meet the specific needs.

For more details, visit the [Allo V2 GitHub Repository](https://github.com/allo-protocol/allo-v2/tree/main) and the [DirectGrantsSimpleStrategy](https://github.com/allo-protocol/allo-v2/tree/main/contracts/strategies/_poc/direct-grants-simple) that inspired our contract's design.


---

## Getting Started

To interact with our platform, clone the repository and install the dependencies. Ensure you have a working knowledge of Solidity, smart contract interactions, and a basic understanding of the Ethereum network.

## License

This project is licensed under [MIT License](LICENSE).

---

Join us in revolutionizing the crowdfunding landscape in the Web3 ecosystem with Decentralized GrantStream! 🚀🌐

---

# Decentralized GrantStream: Crowdfunding Scenarios

## Introduction

This document outlines various scenarios demonstrating the functionality of the Decentralized GrantStream platform, a Web3 crowdfunding ecosystem. Utilizing the Gitcoin Allo V2 protocol, it facilitates a dynamic interaction between project creators (developers) and investors (suppliers).

## Scenario Summaries

### CASE 1: Successful Project Completion

#### Steps:
1. **Project Registration**: A user registers a new project, providing necessary details like funding needs, project name, description, and recipient address.
2. **Funding**: Two investors fund the project, each contributing 0.5 ether, fully funding the project.
3. **Milestone Planning**: The executor (project creator) offers a detailed milestone plan for project execution.
4. **Milestone Review and Approval**: Investors review and approve the offered milestones.
5. **Milestone Submission and Completion**: The executor works on and submits each milestone. Investors review and approve the completed milestones.
6. **Project Completion**: After the last milestone is approved, the project is marked as completed. The executor can send thank-you tokens to investors.

### CASE 2: Project Rejection

#### Steps:
1. **Project Funding**: Similar to Case 1, the project is fully funded by two investors.
2. **Awaiting Milestones**: The project awaits milestone offers from the executor.
3. **Project Rejection**: Due to a lack of progress from the executor, investors decide to revoke their support and vote to reject the project.
4. **Fund Redistribution**: Upon project rejection, funds are redistributed back to the investors.

### CASE 3: Mixed Outcome

#### Steps:
1. **Investor Withdrawal and Reinvestment**: An investor initially withdraws their investment but later decides to reinvest in the project.
2. **Milestone Offering and Rejection**: The executor offers a milestone plan, which is rejected by investors for being unsatisfactory.
3. **Revised Milestone Plan**: The executor offers a new, more detailed milestone plan, which is accepted by investors.
4. **Selective Milestone Approval**: Investors reject the first submitted milestone but approve a revised version. The final milestone, however, is rejected.
5. **Final Project Rejection**: Due to the executor's failure to improve the final milestone, investors eventually vote to reject the entire project.

## Conclusion

These scenarios demonstrate the flexibility and democratic nature of the Decentralized GrantStream platform. It empowers investors to actively participate in project development and ensures accountability from project executors. The platform's design caters to various possible outcomes, from successful project completion to partial success and complete rejection, reflecting real-world investment dynamics in the Web3 ecosystem.


## Future Plans for the Project

As we continue to develop and enhance the Decentralized GrantStream platform, we aim to introduce new features and strategies to improve functionality and user engagement:

1. **Implementation of Three Strategy Types:**
   - **Crowdfunding Strategy:** Designed for executors to actively seek investors.
   - **Bounty Strategy:** Allows investors to wait for executors to take the initiative.
   - **Sub-Strategy:** Functions under a parent strategy with predefined investors and executors, maintaining identical voting weights as the parent strategy.

2. **Integration of ERC-1155 Tokens:**
   - **Voting Token Type:** Minted during each voting round, these tokens facilitate the delegation of voting rights, with a potential sub-delegation process visualized as a linked list and tracked via Hats and ERC-1155 NFTs.
   - **Reputation Token Type:** Aimed at building user reputation, these non-transferable tokens can be minted or revoked by the management contract, offering benefits like loans for executors with high reputation and additional voting power for reputable investors.

3. **Delegate/Revoke & Sub-Delegate/Revoke Voting Rights:**
   A sophisticated system for the delegation and revocability of voting rights, allowing investors to delegate their voting tokens to managers, who can then sub-delegate to others, creating a hierarchical structure. This process is tracked using the Hats protocol and the project's ERC-1155 tokens, establishing a tiered system of delegation where any Hat at a higher level can revoke voting rights from any below it.

4. **Enhanced Strategy Features:**
   - Implementation of more complex voting mechanisms, with vote allocation to milestones as demonstrated in the _qv_allocate function of the QVBaseStrategy contract.
   - Implementation of voting tracked and weighted by the ERC1155 NFT for all milestone voting procedures.
   - Implementation of Quadratic Voting tracked and weighted by the ERC1155 NFT for the addition of new Recipients and Manager voting procedures.
   - Introduction of the ability to include sub-tasks by creating a Sub-Strategy without the need for creating new voting tokens or financing a new project to acquire these rights.
   - Addition of multiple executors, expanding beyond the current limitation of only a single executor.
   - Facilitation of new managers and executors' inclusion through a democratic voting process.

5. **Utilization of the Hats Protocol and Guild for Discord Roles:**
   - Establishing a new Discord branch for each strategy to enable efficient discussion and collaboration among participants.
