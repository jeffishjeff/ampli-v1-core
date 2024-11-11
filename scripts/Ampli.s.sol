// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "forge-std/Script.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {HookMiner} from "../test/utils/HookMiner.sol";
import {RiskConfigs, IRiskConfigs} from "../src/modules/RiskConfigs.sol";
import {Ampli, IRiskGovernor} from "../src/Ampli.sol";

contract DeployAmpli is Script {
    struct NetworkCfg {
        Ampli.ConstructorArgs constructorArgs;
        address expectedAddress;
        bytes32 salt;
    }

    // forge create2 deployer
    address CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);

    uint160 constant AMPLI_HOOK_FLAGS = uint160(
        Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | Hooks.BEFORE_SWAP_FLAG
            | Hooks.AFTER_SWAP_FLAG
    );

    NetworkCfg UnichainSepolia = NetworkCfg(
        Ampli.ConstructorArgs(
            IPoolManager(address(0xC81462Fec8B23319F288047f8A03A57682a35C1A)),
            3000,
            60,
            "Ampli v1 PED",
            "PEDv1",
            18,
            IRiskGovernor(address(0xB97CBB5007f752958C876d1C76efA4aa0c0B23a1)),
            RiskConfigs.RiskParams(IRiskConfigs.InterestMode.Normal, 1e8, 1e9, 9e17, 1e16)
        ),
        address(0),
        bytes32(0x0)
    );

    function getConfig() private returns (NetworkCfg memory) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        if (chainId == 1301) return UnichainSepolia;

        revert("no config found.");
    }

    function run() external {
        NetworkCfg memory cfg = getConfig();

        bytes memory initCode = abi.encodePacked(type(Ampli).creationCode, abi.encode(cfg.constructorArgs));
        bytes32 initCodeHash = keccak256(initCode);

        if (cfg.expectedAddress == address(0)) {
            (cfg.expectedAddress, cfg.salt) = HookMiner.findSalt(CREATE2_DEPLOYER, AMPLI_HOOK_FLAGS, initCodeHash);
        }

        console.log("expected hook address: ", cfg.expectedAddress);
        console.log("salt:", vm.toString(cfg.salt));

        vm.startBroadcast();
        address deployedAddress;
        bytes32 salt = cfg.salt;
        assembly {
            deployedAddress := create2(0, add(initCode, 0x20), mload(initCode), salt)
        }
        vm.stopBroadcast();
        console.log("deployed hook address: ", deployedAddress);

        require(deployedAddress == cfg.expectedAddress, "DeployScript: hook address mismatch");
    }
}
