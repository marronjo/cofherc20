// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/Test.sol";
import {HybridFHERC20} from "../src/HybridFHERC20.sol";
import {Queue} from "../src/Queue.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-foundry-mocks/CoFheTest.sol";
import "@fhenixprotocol/cofhe-contracts/FHE.sol";

contract QueueTest is Test {
    CoFheTest CFT;
    address bob = makeAddr("bob");

    HybridFHERC20 private token;

    Queue private queue;

    uint32 private startingBalance = 15;

    function setUp() public {

        vm.label(bob, "bob");
        CFT = new CoFheTest(false);

        queue = new Queue();
        token = new HybridFHERC20("TOKEN", "TOK");
        
        InEuint128 memory amount = CFT.createInEuint128(startingBalance, bob);

        vm.startPrank(bob);
        token.mintEncrypted(bob, amount);

        token.decryptBalance(bob);

        uint256 unwrapped = euint128.unwrap(token.encBalances(bob));
        queue.push(bytes32(unwrapped));

        vm.stopPrank();
    }

    function testQueueDecryptPolling() public {
        assertEq(queue.length(), 1);    //ensure value pushed onto queue in setUp

        uint256 first = uint256(queue.peek());
        euint128 handle = euint128.wrap(first);

        uint8 count = 0;
        bool success = false;
        while (!success && count < 100) {
            (uint256 result, bool decrypted) = FHE.getDecryptResultSafe(handle);
            if (decrypted) {
                assertEq(result, startingBalance);  //ensure correct decrypted value
                success = true;
            } else {
                vm.warp(block.timestamp + 1);
                count += 1;
            }
        }

        uint256 popped = uint256(queue.pop());      //pop decrypted value from queue, no longer needed

        assertEq(first, popped);                    //ensure same value from peek and pop

        assertEq(queue.length(), 0);                //ensure queue is empty after operations
        assertEq(queue.empty(), true);              //...
    }
}
