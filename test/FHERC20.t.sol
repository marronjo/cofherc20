// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {FHERC20} from "../src/FHERC20.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-foundry-mocks/CoFheTest.sol";
import "@fhenixprotocol/cofhe-contracts/FHE.sol";

contract FHERC20Test is Test {
    CoFheTest CFT;
    address bob = makeAddr("bob");

    FHERC20 private token;

    uint32 private startingBalance = 15;

    function setUp() public {
        CFT = new CoFheTest(false);
        token = new FHERC20("TOKEN", "TOK");   

        InEuint32 memory amount = CFT.createInEuint32(startingBalance, bob);
        vm.prank(bob);
        token.mintEncrypted(amount);
    }

    function test_mintEncrypted() public {
        InEuint32 memory amount = CFT.createInEuint32(30, bob);
        vm.prank(bob);
        token.mintEncrypted(amount);

        CFT.assertHashValue(token.encryptedBalances(address(bob)), startingBalance + 30);
    }

    function test_decryptBalance() public {
        CFT.assertHashValue(token.encryptedBalances(address(bob)), startingBalance);
        token.decryptBalance();

        uint8 count = 0;
        bool success = false;
        while (!success && count < 100) {
            try token.getDecryptBalanceResult(token.encryptedBalances(address(bob))) returns (uint32) {
                success = true;
            } catch {
                vm.warp(block.timestamp + 1);
                count += 1;
            }
        }
    }

    function test_decryptBalanceSafe() public {
        CFT.assertHashValue(token.encryptedBalances(address(bob)), startingBalance);
        token.decryptBalance();

        uint8 count = 0;
        bool success = false;
        while (!success && count < 100) {
            (uint256 result, bool decrypted) = token.getDecryptBalanceResultSafe(
                token.encryptedBalances(address(bob))
            );
            if (decrypted) {
                assertEq(result, startingBalance);
                success = true;
            } else {
                vm.warp(block.timestamp + 1);
                count += 1;
            }
        }
    }
}
