// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Hooks} from "v4-core/libraries/Hooks.sol";

library HookMiner {
    // keep right 14 bits
    uint160 constant MASK = 0x3FFF;

    function findSalt(address deployer, uint160 flags, bytes32 initCodeHash)
        external
        view
        returns (address hookAddress, bytes32 salt)
    {
        assembly {
            // Preserve free memory pointer
            let freeMemPtr := mload(0x40)

            // Setup memory
            //0x00: 00 00 00 00 00 00 00 00 00 00 00 ff |-- address(this) -------------- |
            //0x20: |------------------------ salt ------------------------------------- |
            //0x40: |----------------- keccak256(initCode) ----------------------------- |
            mstore(0x00, deployer)
            mstore8(0x0b, 0xff)
            mstore(0x20, salt)
            mstore(0x40, initCodeHash)

            let valid
            for {} 0x01 {} {
                hookAddress := keccak256(0x0b, 0x55)
                valid := eq(and(hookAddress, MASK), flags)
                if valid { break }
                salt := gas()
                mstore(0x20, salt)
            }

            // Restore free memory pointer
            mstore(0x40, freeMemPtr)
        }
    }
}
