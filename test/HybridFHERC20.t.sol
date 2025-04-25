// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {HybridFHERC20} from "../src/HybridFHERC20.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-foundry-mocks/CoFheTest.sol";
import "@fhenixprotocol/cofhe-contracts/FHE.sol";

contract HybridFHERC20Test is Test {
    CoFheTest CFT;
    address bob = makeAddr("bob");

    HybridFHERC20 private token;

    uint32 private startingBalance = 15;

    function setUp() public {
        CFT = new CoFheTest(false);
        token = new HybridFHERC20("TOKEN", "TOK");

        vm.label(bob, "bob");

        InEuint128 memory amount = CFT.createInEuint128(startingBalance, bob);
        vm.prank(bob);
        token.mintEncrypted(bob, amount);
    }

    function test_mintEncrypted() public {
        InEuint128 memory amount = CFT.createInEuint128(30, bob);
        vm.prank(bob);
        token.mintEncrypted(bob, amount);

        CFT.assertHashValue(token.encBalances(address(bob)), startingBalance + 30);
    }

    function test_decryptBalance() public {
        CFT.assertHashValue(token.encBalances(address(bob)), startingBalance);
        

        uint8 count = 0;
        bool success = false;
        while (!success && count < 100) {
            try token.getDecryptBalanceResult(address(bob)) returns (uint128) {
                success = true;
            } catch {
                vm.warp(block.timestamp + 1);
                count += 1;
            }
        }
    }

    function test_decryptBalanceSafe() public {
        CFT.assertHashValue(token.encBalances(address(bob)), startingBalance);
        token.decryptBalance(bob);

        uint8 count = 0;
        bool success = false;
        while (!success && count < 100) {
            (uint256 result, bool decrypted) = token.getDecryptBalanceResultSafe(address(bob));
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
