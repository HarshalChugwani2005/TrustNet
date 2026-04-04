# TrustNet

TrustNet is a hybrid peer-to-peer lending platform built with Flutter, Firebase, and Web3 tooling. It combines a mobile-first user experience with on-chain loan requests and an auditable lending flow.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Firestore](https://img.shields.io/badge/Cloud%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/products/firestore)
[![Web3](https://img.shields.io/badge/Web3-d9d9d9?logo=ethereum&logoColor=black)](https://flutter.dev/)

## Overview

TrustNet lets borrowers request funding, lenders review opportunities, and both sides track loan activity through a transparent ledger and a dynamic trust score. The app uses Firebase for identity, profiles, notifications, and local state, while the lending contract can broadcast requests to Base Sepolia through Web3 JSON-RPC.

## Core Capabilities

- Authentication with Firebase Auth and Google Sign-In
- User profiles, wallet linking, and secure private key storage
- Loan request and repayment tracking
- Dynamic trust score updates based on repayment behavior
- Transaction ledger and notification feed
- Optional on-chain loan requests through a Solidity smart contract
- Localization support and a shared Flutter navigation shell

## Architecture

- Presentation layer: Flutter screens, theme, and navigation
- State management: Provider for locale and user state
- Backend: Firebase Authentication and Cloud Firestore
- Blockchain layer: `web3dart` client connected to Base Sepolia
- Secure storage: `flutter_secure_storage` for wallet private keys
- Smart contract: `contracts/TrustNetLendingPool.sol`

## Project Structure

- `lib/app.dart` - app shell, theme, routes, and localization
- `lib/main.dart` - Firebase initialization and app bootstrap
- `lib/screens/` - auth flow, dashboard, loan, ledger, and notification screens
- `lib/services/` - auth, wallet, loan, notification, and Web3 integration
- `lib/models/` - user, loan, and notification data models
- `contracts/` - Solidity contract for on-chain lending flow
- `test/` - unit and widget tests

## Technology Stack

- Flutter
- Firebase Auth
- Cloud Firestore
- Google Sign-In
- web3dart
- http
- flutter_secure_storage
- provider
- intl and flutter_localizations

## Getting Started

### Prerequisites

- Flutter SDK compatible with Dart `^3.11.0`
- Firebase project configured for the app
- Base Sepolia RPC endpoint if you want on-chain lending enabled

### Setup

1. Install dependencies:

	```bash
	flutter pub get
	```

2. Verify Firebase configuration:

	- `lib/firebase_options.dart` is already included for Firebase initialization.
	- Android and web Firebase config files are already present in the project.

3. Configure blockchain environment variables for lending contract calls:

	- `BASE_SEPOLIA_RPC_URL`
	- `TRUSTNET_LENDING_CONTRACT`
	- Optional: `BASE_SEPOLIA_CHAIN_ID` (defaults to `84532`)

4. Run the app:

	```bash
	flutter run
	```

## Security Notes

- Private keys are generated with `Random.secure()` and stored with platform secure storage.
- On-chain transactions are signed locally before broadcast.
- Firestore rules restrict reads and writes to authenticated users.
- Smart contract calls use explicit chain ID configuration to reduce replay risk.

## On-Chain Lending Flow

1. The borrower creates a loan request in the app.
2. The app signs the transaction with the user wallet.
3. `web3dart` sends the request to the Base Sepolia RPC endpoint.
4. The `TrustNetLendingPool` contract records the loan and emits events.
5. The app and Firestore layer keep profile, trust score, and notification data in sync.

## Notes

- The project currently uses a fully decentralized stack.
- Firebase handles authentication, user profiles, notifications, and trust-score persistence.
- The blockchain layer is used for verifiable lending transactions and auditability.
