# Clarity Flash Loan Provider

A simple yet powerful flash loan implementation for the Stacks blockchain written in Clarity.

## Overview

This project implements a flash loan provider that allows users to borrow assets without collateral as long as they repay the loan within the same transaction. The contract includes:

- Fee structure management
- Use case restrictions
- Liquidity pool management
- Flash minting capabilities (optional)
- Administrative controls

## How Flash Loans Work

Flash loans are uncollateralized loans that must be borrowed and repaid within a single transaction. This is possible because if the borrower fails to repay, the entire transaction reverts and it's as if the loan never happened.

Key benefits:
- No collateral required
- Access to large amounts of capital
- Immediate execution

## Contract Features

### Core Functionality

- **Borrow without collateral**: Users can borrow assets without providing collateral
- **Single-transaction execution**: Loans must be borrowed and repaid in the same transaction
- **Fee structure**: A fixed 0.5% fee is applied to all loans
- **Liquidity management**: Users can add liquidity to earn a portion of fees

### Advanced Features

- **Flash minting**: Optional feature to create tokens on-demand for flash loans
- **Admin controls**: Contract owner can adjust parameters and recover from errors
- **Use case tracking**: Tracks active loans to prevent reentrancy attacks
- **Maximum loan limits**: Configurable caps on loan amounts

## Functions

### For Users

- `flash-loan`: Borrow assets without collateral
- `repay-flash-loan`: Repay borrowed assets plus fee
- `add-liquidity`: Add liquidity to the flash loan pool
- `get-liquidity`: Check current available liquidity
- `calculate-fee`: Calculate the fee for a loan amount

### For Administrators

- `set-contract-owner`: Transfer ownership of the contract
- `set-flash-minting`: Enable or disable flash minting
- `set-max-flash-loan`: Set maximum flash loan amount
- `remove-liquidity`: Remove liquidity from the pool (owner only)
- `force-clear-loan`: Emergency function to clear stuck loans

## Error Codes

The contract defines the following error codes:

| Code | Description |
|------|-------------|
| `ERR_UNAUTHORIZED` | Caller doesn't have permission |
| `ERR_INSUFFICIENT_FUNDS` | Not enough liquidity for the requested loan |
| `ERR_LOAN_ALREADY_ACTIVE` | Borrower already has an active loan |
| `ERR_NO_ACTIVE_LOAN` | No active loan found for the borrower |
| `ERR_REPAYMENT_TOO_LOW` | Repayment amount is less than required |
| `ERR_INVALID_AMOUNT` | Invalid loan or liquidity amount |
| `ERR_FLASH_MINTING_DISABLED` | Flash minting is not enabled |
| `ERR_FLASH_LOAN_REENTRANCY` | Reentrancy attempt detected |

## How to Use

### Setting Up

1. Deploy the contract to the Stacks blockchain
2. Add liquidity to the pool using the `add-liquidity` function

### Creating a Flash Loan

To utilize a flash loan:

1. Call `flash-loan` with the desired amount and recipient
2. Execute your intended operation (arbitrage, liquidation, etc.)
3. Call `repay-flash-loan` to repay the loan plus fee

### Example Use Case: Arbitrage

```
1. Identify price difference between exchanges
2. Call flash-loan to borrow funds
3. Buy asset on exchange A
4. Sell asset on exchange B at higher price
5. Call repay-flash-loan with original amount plus fee
6. Keep the profit
```

## Development

### Requirements

- [Clarinet](https://github.com/hirosystems/clarinet) for local development and testing
- [Stacks.js](https://github.com/stacks-network/stacks.js) for frontend integration

### Testing

1. Clone the repository
2. Run `clarinet check` to verify the contract
3. Run `clarinet test` to execute test cases

## Security Considerations

- **Reentrancy protection**: The contract tracks active loans to prevent reentrancy attacks
- **Owner controls**: Administrative functions are restricted to the contract owner
- **Amount validation**: All amounts are validated before processing

## License

This project is open source and available under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.