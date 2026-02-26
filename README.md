# Stacks Prediction Hub

A decentralized prediction market platform built on the Stacks blockchain using Clarity smart contracts. Users can create binary and multi-outcome prediction markets, provide liquidity, and earn rewards for participation.

## Architecture

The platform consists of five interconnected smart contracts:

### Contracts

**binary-market** - Binary yes/no prediction markets with Constant Product Market Maker (CPMM) pricing. Users can create markets with a description and deadline, buy yes or no shares using STX, and claim winnings after resolution. A 2% platform fee is applied to each trade.

**categorical-market** - Multi-outcome prediction markets supporting up to 5 distinct outcomes. Participants buy shares in their preferred outcome. Once resolved, winners receive proportional payouts from the total prize pool. A 2.5% fee is collected on share purchases.

**market-resolver** - Oracle-based resolution system with dispute protection. Authorized resolvers propose outcomes, which enter a 144-block dispute period (~1 day). Anyone can dispute a resolution by posting a 1 STX bond. The contract owner arbitrates disputes and can perform emergency resolutions if needed.

**liquidity-engine** - Automated Market Maker (AMM) liquidity system. Liquidity providers deposit balanced reserves into pools and receive LP tokens. The engine handles swaps with a 0.5% fee that accrues to LPs. Providers can add or remove liquidity and claim accumulated fee rewards.

**rewards-distributor** - Incentive system tracking user activity through a points system. Traders earn 10 points per trade, market creators earn 50 points, and resolvers earn 25 points. Points determine weekly epoch reward distributions and a tiered ranking system (Bronze, Silver, Gold, Diamond).

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v2.0+
- [Node.js](https://nodejs.org/) v18+

### Setup

```bash
git clone https://github.com/serayd61/stacks-prediction-hub.git
cd stacks-prediction-hub
npm install
```

### Check Contracts

```bash
clarinet check
```

### Run Tests

```bash
clarinet test
```

### Interactive Console

```bash
clarinet console
```

## Contract Details

| Contract | Purpose | Fee |
|----------|---------|-----|
| binary-market | Yes/No markets | 2.0% |
| categorical-market | Multi-outcome markets (2-5) | 2.5% |
| market-resolver | Oracle resolution + disputes | 1 STX bond |
| liquidity-engine | AMM pools + LP rewards | 0.5% |
| rewards-distributor | Points + weekly rewards | None |

## Reward Tiers

| Tier | Points Required |
|------|----------------|
| Unranked | 0 |
| Bronze | 100 |
| Silver | 1,000 |
| Gold | 5,000 |
| Diamond | 10,000 |

## License

MIT
