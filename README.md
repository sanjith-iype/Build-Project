# Decentralized Crowdfunding

A Solidity-based decentralized crowdfunding system developed as part of the Build Fellowship and deployed to the Ethereum Sepolia test network.

## Overview

This project implements a crowdfunding smart contract where users can create campaigns, contribute ETH, vote on campaign milestones, and receive refunds when campaigns fail to reach their funding targets.

Rather than releasing all raised funds immediately, campaigns can define milestones that must be approved by a majority of contributors before funds are released to the campaign creator.

## Features

- Create crowdfunding campaigns with:
  - Name and description
  - Funding target
  - Deadline
  - Multiple funding milestones
- Contribute ETH to active campaigns
- Track individual contributor balances
- Allow contributors to vote on milestones
- Release milestone funds after majority approval
- Refund contributors when unsuccessful campaigns expire
- Finalize completed campaigns
- Query campaign, contributor, milestone, and funding information

## Tech Stack

- Solidity
- Ethereum
- Sepolia Testnet

## Smart Contract Design

The contract uses two primary data structures:

### Campaign

Each campaign stores:

- Campaign ID
- Name and description
- Funding target
- Deadline
- Creator
- Total contributions
- Contributors
- Milestones
- Refund status
- Finalization state

### Milestone

Each milestone stores:

- Requested funding amount
- Description
- Approval status
- Vote count
- Contributor voting records

Contributors may vote once per milestone. Once more than half of the campaign's contributors approve a milestone, the corresponding funds are released to the campaign creator.

## Core Functions

`createCampaign()`  
Creates a new campaign with a funding target, deadline, and milestone structure.

`contribute()`  
Allows users to contribute ETH to an active campaign.

`approveMilestone()`  
Allows contributors to vote on a funding milestone.

`claimRefund()`  
Allows contributors to recover their contribution if the campaign fails to reach its target before the deadline.

`finalizeCampaign()`  
Marks a campaign as completed after its deadline.

The contract also includes helper functions for retrieving campaign, milestone, contributor, and contribution information.

## Deployment

The contract was deployed to the Ethereum Sepolia test network.

**Contract Address**

```text
0x2c24d2f202225c90887594b933b9ce29f7f900de
