<div align="center">

# TrustNet

Peer-to-peer lending platform built with Flutter + Firebase.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Cloud%20Firestore](https://img.shields.io/badge/Cloud%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/products/firestore)

</div>

## 🧾 Project Info
TrustNet is a peer-to-peer (P2P) lending mobile application that enables individuals to lend and borrow money without relying on traditional banks.

It emphasizes trust, transparency, and accountability through:
- 📈 A reputation-based (dynamic) credit score
- 📒 A transparent transaction ledger

**High-level flow (conceptual):**

```mermaid
flowchart LR
	U[👤 User] --> A[🔐 Firebase Authentication]
	A --> P[🪪 Profile Verification]
	P --> S[📈 Dynamic Credit Score]

	B[🙋 Borrower] --> R[📝 Create Loan Request]
	L[🤝 Lender] --> V[🔎 View & Evaluate Requests]
	V --> S
	L --> F[💸 Fund Loan]
	R --> F

	F --> Lg[📒 Public Ledger (Firestore)]
	Pay[💳 Repayment (Tracked)] --> Lg
```

## ✨ Key Features
### 🔐 Authentication
- 🔑 Secure login/signup using Firebase Authentication
- 📧📱 Email/phone-based authentication

### 🪪 User Identity & Trust
- 🧾 Profile-based verification
- 📊 Dynamic credit score system based on user behavior

### 🤝 Lending System
- 🙋 Borrowers can create loan requests
- 💸 Lenders can view loan requests and fund loans

### 🧠 Risk Assessment (Credit Scoring)
Simple rule-based credit scoring:
- ✅ On-time repayment → score increases
- ⚠️ Late repayment / default → score decreases

### 📒 Transparent Ledger
- 📜 All transactions are recorded in a public ledger
- 👀 Ensures visibility and accountability

### 🧾 Repayment Tracking
Track loan status:
- 🟡 Pending
- 🟢 Funded
- ✅ Repaid
- 🔴 Defaulted

### 💳 Payments (Optional)
- Razorpay integration (or simulated transactions)

## 🧰 Tech Stack
- 📱 **Frontend:** Flutter
- ☁️ **Backend:** Firebase
- 🗄️ **Database:** Cloud Firestore
- 🔐 **Authentication:** Firebase Authentication
- 💳 **Payments (optional):** Razorpay (or simulated transactions)
