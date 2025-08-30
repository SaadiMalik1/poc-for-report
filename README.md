# Proof of Concept: Vulnerabilities in ReferralManager Contract

This repository contains a working Proof of Concept using the Foundry testing framework to demonstrate two security vulnerabilities in the `ReferralManager` smart contract.

## Vulnerabilities Found

### 1.  Handler Abuse (Rebate Hijacking)

-   **Description:** A privileged `handler` address has the unilateral authority to change any trader's associated referral code using the `setReferrerCodeFor()` function. A malicious or compromised handler can exploit this to overwrite a high-volume trader's legitimate referral code with one they control, effectively hijacking all future rebate rewards.
-   **PoC Test:** `test_poc_handlerCanHijackReferral()` in `test/ReferralManager.t.sol`.

### 2. Invalid Referral Code on Secondary Networks

-   **Description:** The contract's multi-chain architecture only validates the existence of referral codes on the `PRIMARY_NETWORK` (Arbitrum, chain ID 42161). On any other chain, a user can call `setReferrerCode()` with any `bytes32` value, including non-existent or garbage data. This pushes the burden of validation entirely off-chain and can lead to lost rewards, user confusion, and potential errors in the reward distribution system.
-   **PoC Test:** `test_poc_canSetInvalidCodeOnSecondaryNetwork()` in `test/ReferralManager.t.sol`.

## Prerequisites

-   [Foundry](https://getfoundry.sh/) (includes `forge` and `anvil`) must be installed.

## How to Run the Proof of Concept

1.  **Clone the repository:**
    ```bash
    git clone <REPOSITORY_URL>
    cd referral_poc
    ```

2.  **Run the tests:**
    ```bash
    forge test -vvv
    ```

## Expected Output

You should see both tests pass successfully. The test logs will print messages confirming that the attack steps were executed as planned.

-   `test_poc_handlerCanHijackReferral` will pass, showing that the handler successfully overwrote the trader's referral code.
-   `test_poc_canSetInvalidCodeOnSecondaryNetwork` will pass, showing that the contract allowed an unregistered code to be set on a simulated secondary network.

```Suite result: ok. 2 passed; 0 failed; 0 skipped;
...
Ran 2 test suites in ...: 4 tests passed, 0 failed, 0 skipped (4 total tests)
```
