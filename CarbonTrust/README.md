# CarbonTrust

## CarbonVerify: Blockchain-Based Carbon Credit Verification System

CarbonTrust is a blockchain-based solution for verifying, tracking, and trading carbon credits on the Stacks blockchain. The CarbonVerify smart contract provides a secure, transparent, and immutable system for carbon credit issuance, verification, and trading.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Smart Contract Architecture](#smart-contract-architecture)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
  - [Deploying the Contract](#deploying-the-contract)
  - [Interacting with the Contract](#interacting-with-the-contract)
- [API Reference](#api-reference)
  - [Administrative Functions](#administrative-functions)
  - [Core Certificate Functions](#core-certificate-functions)
  - [Read-Only Functions](#read-only-functions)
- [Use Cases](#use-cases)
- [Development Roadmap](#development-roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## Overview

CarbonTrust addresses the challenges in the voluntary carbon market by providing a transparent mechanism for carbon credit verification and trading. The platform leverages blockchain technology to ensure the integrity, traceability, and uniqueness of carbon credits, preventing double-counting and enhancing trust in the market.

The CarbonVerify smart contract, built on Clarity language for the Stacks blockchain, serves as the backbone of this system, providing a secure and transparent ledger for carbon credit management.

## Features

- **Secure Certificate Issuance**: Only verified entities can issue carbon credit certificates
- **Transparent Verification Process**: All verification data is stored on-chain
- **Immutable Record-Keeping**: Complete history of certificate transfers is maintained
- **Certificate Lifecycle Management**: Time-bound validity for certificates
- **Role-Based Access Control**: Dedicated roles for administrators, verifiers, and certificate holders
- **Certificate Transfer Mechanism**: Secure transfer of certificates between entities
- **Detailed Certificate Metadata**: Region, method, project details stored with each certificate

## Smart Contract Architecture

The CarbonVerify smart contract is built around the following components:

### Data Structures

- **Certificates**: Main data structure storing carbon credit details including:
  - Carbon amount
  - Producer information
  - Issuance time
  - Validity period
  - Region
  - Verification method
  - Project ID

- **Certificate Holders**: Mapping between addresses and owned certificates
- **Transaction History**: Comprehensive record of all certificate transfers
- **Verifiers Registry**: Authorized entities who can verify carbon credits

### Core Functions

- **Certificate Issuance**: Creating new verified carbon credits
- **Certificate Transfer**: Trading carbon credits between entities
- **Verifier Management**: Adding and removing authorized verifiers

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet): Clarity development environment
- [Stacks Wallet](https://www.hiro.so/wallet): For interacting with the deployed contract
- Basic knowledge of Clarity and Stacks blockchain

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/carbon-ledger.git
cd carbon-ledger
```

2. Install development dependencies:
```bash
npm install
```

3. Initialize the Clarinet environment:
```bash
clarinet new
```

4. Copy the CarbonVerify contract to the contracts directory:
```bash
cp src/contracts/carbon-verify.clar contracts/
```

## Usage

### Deploying the Contract

1. Configure the deployment settings in the `Clarinet.toml` file:
```toml
[contracts.carbon-verify]
path = "contracts/carbon-verify.clar"
depends_on = []
```

2. Deploy the contract using Clarinet:
```bash
clarinet deploy
```

### Interacting with the Contract

#### As an Administrator

The deployer of the contract automatically becomes the administrator with the ability to:

```clarity
;; Add a verifier to the system
(contract-call? .carbon-verify add-verifier 'STVERIFIERADDRESS)

;; Remove a verifier from the system
(contract-call? .carbon-verify deactivate-verifier 'STVERIFIERADDRESS)
```

#### As a Verifier

Authorized verifiers can issue new carbon certificates:

```clarity
;; Issue a new carbon credit certificate
(contract-call? .carbon-verify issue-certificate 
    'STPRODUCERADDRESS  ;; producer address
    u1000               ;; carbon amount (in tons)
    "California, USA"   ;; region
    "Solar"             ;; method
    "SOL-CAL-2025-001"  ;; project ID
)
```

#### As a Certificate Holder

Certificate holders can transfer their certificates:

```clarity
;; Transfer a certificate to another entity
(contract-call? .carbon-verify transfer-certificate 
    u1                  ;; certificate ID
    'STRECIPIENTADDRESS ;; recipient address
)
```

#### Reading Certificate Data

Anyone can query certificate data:

```clarity
;; Get certificate details
(contract-call? .carbon-verify get-certificate u1)

;; Check if a certificate is expired
(contract-call? .carbon-verify is-certificate-expired u1)

;; Get certificate transfer history
(contract-call? .carbon-verify get-transfer-history u1 u0)
```

## API Reference

### Administrative Functions

#### `add-verifier`
Adds a new authorized verifier to the system.

```clarity
(define-public (add-verifier (verifier principal)))
```

- **Parameters**:
  - `verifier`: The principal address to be added as a verifier
- **Returns**: OK on success or error if not authorized
- **Restrictions**: Can only be called by the contract administrator

#### `deactivate-verifier`
Removes a verifier from the authorized list.

```clarity
(define-public (deactivate-verifier (verifier principal)))
```

- **Parameters**:
  - `verifier`: The principal address to be removed
- **Returns**: OK on success or error if not authorized
- **Restrictions**: Can only be called by the contract administrator

### Core Certificate Functions

#### `issue-certificate`
Issues a new carbon credit certificate.

```clarity
(define-public (issue-certificate
    (producer principal)
    (carbon-amount uint)
    (region (string-ascii 50))
    (method (string-ascii 20))
    (project-id (string-ascii 34))))
```

- **Parameters**:
  - `producer`: The entity that produced the carbon credits
  - `carbon-amount`: Amount of carbon credits in tons
  - `region`: Geographic location of the project
  - `method`: The carbon reduction method used
  - `project-id`: Unique identifier for the project
- **Returns**: The ID of the newly created certificate
- **Restrictions**: Can only be called by authorized verifiers

#### `transfer-certificate`
Transfers a certificate to a new holder.

```clarity
(define-public (transfer-certificate (certificate-id uint) (recipient principal)))
```

- **Parameters**:
  - `certificate-id`: The ID of the certificate to transfer
  - `recipient`: The recipient's address
- **Returns**: OK on success or error if conditions aren't met
- **Restrictions**: Can only be called by the current certificate holder

### Read-Only Functions

#### `get-certificate`
Retrieves details of a specific certificate.

```clarity
(define-read-only (get-certificate (certificate-id uint)))
```

#### `is-verifier`
Checks if an address is an authorized verifier.

```clarity
(define-read-only (is-verifier (address principal)))
```

#### `is-certificate-expired`
Checks if a certificate has expired.

```clarity
(define-read-only (is-certificate-expired (certificate-id uint)))
```

#### `get-history-count`
Gets the number of transfer records for a certificate.

```clarity
(define-read-only (get-history-count (certificate-id uint)))
```

#### `get-transfer-history`
Retrieves a specific transfer record for a certificate.

```clarity
(define-read-only (get-transfer-history (certificate-id uint) (history-index uint)))
```

## Use Cases

### Carbon Credit Producers
- Register carbon reduction projects
- Receive verified carbon credit certificates
- Trade certificates with buyers
- View complete certificate history

### Carbon Credit Verifiers
- Validate carbon reduction claims
- Issue verified carbon credit certificates
- Maintain reputation through transparent verification

### Carbon Credit Buyers
- Purchase verified carbon credits
- Verify authenticity of certificates
- Track provenance of carbon credits
- Retire credits for offsetting purposes

## Development Roadmap

### Phase 1: Core Functionality (Current)
- Basic certificate issuance and transfer
- Verifier management
- Certificate expiration

### Phase 2: Enhanced Features
- Certificate batching for efficiency
- Fractional certificate transfers
- Certificate retirement mechanism
- Enhanced metadata for better tracking

### Phase 3: Integration & Expansion
- Oracle integration for off-chain verification data
- Cross-chain bridges for broader market access
- API for third-party application integration
- Analytics dashboard for market insights

## Contributing

We welcome contributions to the CarbonTrust project! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
