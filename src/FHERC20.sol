// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@fhenixprotocol/cofhe-contracts/FHE.sol";

contract FHERC20 is ERC20 {
    mapping(address => euint32) public encryptedBalances;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mintEncrypted(InEuint32 memory amount) public {
        euint32 updatedBalance = FHE.add(encryptedBalances[msg.sender], FHE.asEuint32(amount));
        encryptedBalances[msg.sender] = updatedBalance;
        FHE.allowThis(encryptedBalances[msg.sender]);
    }

    function decryptBalance() public {
        FHE.decrypt(encryptedBalances[msg.sender]);
    }

    function getDecryptBalanceResult(euint32 input1) public view returns (uint32) {
        return FHE.getDecryptResult(input1);
    }

    function getDecryptBalanceResultSafe(euint32 input1) public view returns (uint32 value, bool decrypted) {
        return FHE.getDecryptResultSafe(input1);
    }
}
