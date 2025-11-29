## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
**Project Overview**

- **Name:** Receipt Token (ERC721 receipts + Procurement system)
- **Purpose:** Mint receiptable NFTs (image CID on IPFS) and provide a procurement system that validates invoices (optionally via a ZK Honk verifier) with daily limits, purchase agreements, and fraud detection.

**Tech Stack**

- **Language:** Solidity (>=0.8.19, project configured to `0.8.30`)
- **Tooling:** Foundry (`forge`, `cast`, `anvil`, `forge-std`) for testing, scripting and deployment
- **Dependencies:** OpenZeppelin contracts, `forge-std` (included under `lib/`)

**Quick Links**

- Source: `src/`
- Tests: `test/`
- Deployment scripts: `script/` and `deploy_*.sh`
- Config: `foundry.toml`

**Prerequisites**

- Install Foundry: `curl -L https://foundry.paradigm.xyz | bash` then `foundryup`
- Set environment variables in a `.env` file at project root:
	- `LISK_SEPOLIA_RPC_URL` — RPC endpoint (e.g. `https://rpc.sepolia-api.lisk.com`)
	- `PRIVATE_KEY` — deployer private key (test key on Sepolia)

**How to build and test locally**

- Build: `forge build`
- Run tests: `forge test -v`
- Format: `forge fmt`

**Contracts (high-level)**

| Contract | Source File | Deployed Address (Lisk Sepolia 4202) | Description |
|----------|------------|--------------------------------------|-------------|
| SimpleReceiptImages | `src/SimpleReceiptImages.sol` | *Deploy via script* | ERC721 that mints receipts storing IPFS image CID. Provides `storeReceiptImage(string cid)`, `getImageCID`, `tokenURI` (base64 JSON). |
| DailyLimitManager | `src/ProcurementSystem.sol` | `0xb0c14721B209Df0B7Aa87729d0d1b99F32f1cCf1` | Tracks daily spending and enforces daily limits per category/account. |
| PurchaseAgreementManager | `src/ProcurementSystem.sol` | `0x855499Cf21CB94b9Ee3F1b2B7d60457572e7e6c3` | Stores and manages purchase agreements and authorized signers. |
| FraudDetection | `src/ProcurementSystem.sol` | `0x734038A097D7E34e74C6d4B38B99FfdD9d6fbb55` | Basic heuristics and flags for suspicious invoices. |
| ZKInvoiceVerifier | `src/ProcurementSystem.sol` | `0x0368cFF5fEdf278915b6F25bea1622e9C76f4B3B` | Interface and adapter for external Honk ZK verifier. |
| EnhancedInvoiceVerification | `src/ProcurementSystem.sol` | `0xBb9578312514f03684800b36128712fd7D74d07D` | Enhanced invoice verification with composition of managers above. |
| HonkVerifier | `src/verifier.sol` | `0x9E7C8251F45C881D42957042224055d32445805C` | External Honk ZK verifier (auto-generated, large assembly). Causes local compile issues (see Troubleshooting). |



**Common Workflows**

- Deploy SimpleReceiptImages (local or remote):
	- `forge script script/DeploySimpleReceiptImages.sol:DeploySimpleReceiptImages --rpc-url $LISK_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast`
- Deploy Procurement System (references Honk verifier):
	- `forge script script/DeployProcurementSystem.sol:DeployProcurementSystem --rpc-url $LISK_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast`
- Verify deployed contracts (script-based checks for unsupported chains):
	- `forge script script/VerifyContract.sol:VerifyContract --rpc-url $LISK_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast`

**Testing guidance**

- Unit tests are in `test/` and use `forge-std/Test.sol` helpers.
- Run all tests: `forge test -v`
- Notable tests:
	- `test/simpleReceipt.t.sol` — comprehensive tests for `SimpleReceiptImages` (16 tests currently passing)
	- `test/procurement.t.sol` — procurement flows (7 tests currently passing)

**Scripts and helpers**

- `script/DeploySimpleReceiptImages.sol` — Foundry script to deploy the receipt NFT contract
- `script/DeployProcurementSystem.sol` — Foundry script to deploy procurement manager contracts and wire them together
- `script/VerifyContract.sol` — Script that runs on-chain sanity checks when classic Sourcify/Etherscan verification isn't available for the target chain
- `deploy.sh` / `deploy_procurement.sh` — Simple wrappers that source `.env` and run the above `forge script` commands

**Node.js Integration Example**

You can interact with deployed contracts using `ethers.js` or `web3.js`. Example with ethers.js:

```javascript
const { ethers } = require("ethers");

// RPC provider
const provider = new ethers.providers.JsonRpcProvider(
  "https://rpc.sepolia-api.lisk.com"
);

// Connect signer (deployer)
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// SimpleReceiptImages ABI (minimal example)
const SimpleReceiptImagesABI = [
  "function storeReceiptImage(string memory _imageCID) external returns (uint256)",
  "function getImageCID(uint256 tokenId) external view returns (string)",
  "function tokenURI(uint256 tokenId) external view returns (string)"
];

// Connect to deployed contract
const receiptTokenAddress = "0x<deployed-address>"; // From deployment
const receiptContract = new ethers.Contract(
  receiptTokenAddress,
  SimpleReceiptImagesABI,
  signer
);

// Example: Store a receipt image
async function storeReceipt() {
  const imageCID = "QmXxxx..."; // IPFS CID
  const tx = await receiptContract.storeReceiptImage(imageCID);
  await tx.wait();
  console.log("Receipt stored:", tx.hash);
}

// Example: Retrieve receipt metadata
async function getReceipt(tokenId) {
  const cid = await receiptContract.getImageCID(tokenId);
  console.log("Image CID:", cid);
}

storeReceipt().catch(console.error);
```

**For Procurement System**, interact similarly:

```javascript
const ProcurementSystemABI = [
  "function submitInvoice(address vendor, uint256 amount, string memory ipfsHash) external returns (uint256)",
  "function approveInvoice(uint256 invoiceId) external",
  "function verifyInvoiceZKProof(uint256 invoiceId, bytes calldata proof) external"
];

const procurementAddress = "0x<procurement-contract-address>";
const procurementContract = new ethers.Contract(
  procurementAddress,
  ProcurementSystemABI,
  signer
);

// Submit an invoice
async function submitInvoice() {
  const tx = await procurementContract.submitInvoice(
    "0xVendorAddress",
    ethers.utils.parseEther("100"),
    "QmInvoiceCID..."
  );
  await tx.wait();
  console.log("Invoice submitted:", tx.hash);
}
```

For more detailed ABIs, inspect the compiled contract JSON in `out/` directory after running `forge build`.

**Troubleshooting & Notes**

- Verifier compilation: `src/verifier.sol` (Honk verifier) contains large, assembly-heavy auto-generated code and may cause `stack too deep` or other compiler errors locally. Options:
	- Use the provided `IHonkVerifier.sol` interface or `MockVerifier.sol` when running local tests.
	- If you need to compile `verifier.sol` locally, try enabling `via_ir = true` in `foundry.toml` and use `solc 0.8.30`. Be aware this may still require refactors (splitting functions or adding `assembly("memory-safe")` annotations in specific blocks).
- RPC / chain support: Some verification services (Sourcify) may not support chain ID `4202`. We use a script-based verification (`script/VerifyContract.sol`) and Blockscout where available.
- Permission errors in scripts: older scripts used `vm.writeFile` or emoji characters that can break compilation—these were removed. If a script fails during broadcast, check that `PRIVATE_KEY` and `LISK_SEPOLIA_RPC_URL` are set.

**Developer Notes & Next Steps**

- If you plan to work on the Honk verifier internals, start by isolating the failing functions and iteratively applying `memory-safe` assembly annotations or splitting large functions into smaller ones to reduce stack usage.
- Consider keeping `IHonkVerifier` and a `MockVerifier` for fast CI and local tests, and only compile the full verifier for deployment pipelines.

If you want, I can:

- Add a short architecture diagram (ASCII or Mermaid) to this `README.md`.
- Open a PR that removes the disabled `verifier.sol` from compilation and centralizes the mock interface usage for local tests.

---

Quick reference commands:

`forge build`
`forge test -v`
`forge script script/DeployProcurementSystem.sol:DeployProcurementSystem --rpc-url $LISK_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast`
