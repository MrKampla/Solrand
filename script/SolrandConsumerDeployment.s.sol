// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";
import { SolrandConsumerExample } from "../contracts/SolrandConsumerExample.sol";

contract SolrandConsumerDeploymentScript is Script {
  function setUp() public {}

  function run() public {
    vm.startBroadcast();

    SolrandConsumerExample example = new SolrandConsumerExample();

    console.log(
      "Deployed SolrandConsumerExample at address: ",
      address(example)
    );

    vm.stopBroadcast();
  }
}
