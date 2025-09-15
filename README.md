# Royaltease - Automated Royalty Distribution Smart Contract

## Overview

**Royaltease** is a Clarity-based smart contract designed to automate royalty distribution for creative works. It allows creators to register works, assign stakeholders, and distribute royalties seamlessly. The system ensures fairness, transparency, and accountability in managing earnings between multiple contributors.

## Features

* **Work Registration**: Creators can register new works with metadata and royalty rate.
* **Stakeholder Management**: Add or update stakeholders with specific royalty shares.
* **Automated Royalty Distribution**: Distributes incoming royalties proportionally to stakeholders.
* **Earnings Tracking**: Each stakeholder can track and withdraw their accumulated royalties.
* **Error Handling**: Clear error codes for invalid operations, insufficient funds, or unauthorized actions.

## Data Structures

* **works**: Stores metadata about each creative work (creator, title, royalty rate, earnings, stakeholder count).
* **work-stakeholders**: Maps stakeholders to their royalty share for a given work.
* **earnings**: Tracks accumulated earnings for each stakeholder.

## Key Functions

### Read-Only

* `get-work-details (work-id uint)` → Returns details of a registered work.
* `get-stakeholder-share (work-id uint) (stakeholder principal)` → Gets a stakeholder’s royalty share.
* `get-earnings (account principal)` → Returns total earnings for an account.

### Public

* `register-work (title string) (royalty-rate uint)` → Registers a new work and assigns creator as sole stakeholder.
* `add-stakeholder (work-id uint) (stakeholder principal) (share uint)` → Adds a stakeholder and adjusts the creator’s share.
* `distribute-royalty (work-id uint) (amount uint)` → Transfers royalty funds to the contract and distributes earnings.
* `withdraw-earnings` → Allows stakeholders to withdraw accumulated earnings.

### Private

* `distribute-share (work-id uint) (stakeholder principal) (amount uint)` → Allocates proportional royalty to stakeholders.

## Error Codes

* `ERR-NOT-AUTHORIZED (u100)` – Unauthorized access.
* `ERR-INVALID-WORK (u101)` – Work not found.
* `ERR-INVALID-STAKEHOLDER (u102)` – Invalid stakeholder reference.
* `ERR-INVALID-SHARE (u103)` – Invalid royalty share value.
* `ERR-SHARES-EXCEED-100 (u104)` – Shares exceed total allowed (100%).
* `ERR-INSUFFICIENT-FUNDS (u105)` – Not enough funds for operation.
* `ERR-TRANSFER-FAILED (u106)` – Transfer operation failed.

## Initialization

* `work-counter` initialized to `0`.
* `contract-owner` set as contract deployer.

## Use Cases

* Musicians sharing royalties with collaborators.
* Authors distributing earnings with co-writers.
* Digital artists sharing royalties with contributors.
