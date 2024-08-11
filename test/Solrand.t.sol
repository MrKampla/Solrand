// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";

import { SolrandConsumer, SolrandLib } from "../contracts/Solrand.sol";
import { SolrandConsumerExample } from "../contracts/SolrandConsumerExample.sol";

contract SolrandTest is Test {
  SolrandConsumerExample public rng;

  function setUp() public {
    rng = new SolrandConsumerExample();
    vm.deal(address(rng), 100 ether);
  }

  //   function _getCurrentDate() private returns (uint256) {
  //     string[] memory cmds = new string[](2);
  //     cmds[0] = "date";
  //     cmds[1] = "+%s";
  //     bytes memory dateEncoded = vm.ffi(cmds);
  //     return uint256(bytes32(dateEncoded));
  //   }

  function _sendEth(address to, uint256 amount) private {
    (bool isSuccess, ) = to.call{ value: amount }("");
    require(isSuccess, "Failed to send ether");
  }

  function test_requestRandomnessLib(uint256 timestamp) public {
    uint requestBlockNumber = block.number;
    uint targetBlockNumber = block.number + 10;
    uint nonce = 1;
    bytes memory requesterIdentifier = abi.encodePacked(
      // arbitrary data like user address, NFT ID they hold, in game points amount, etc.
      "unique requester identifier",
      address(0x1337),
      timestamp
    );

    bytes32 requestId = SolrandLib.requestRandomness(
      targetBlockNumber,
      nonce,
      requesterIdentifier
    );
    assertNotEq(requestId, 0x0);

    vm.roll(targetBlockNumber + 1);

    // Consumer contract should hold this data like shown in the SolrandConsumer
    uint256 randomNumber = uint256(
      SolrandLib.fullfillRandomness(
        requestBlockNumber,
        targetBlockNumber,
        nonce,
        requesterIdentifier
      )
    );
    // unlikely to fail
    assertNotEq(randomNumber, 0);
  }

  function test_SolrandConsumer(uint128 currentBlockNumber) public {
    uint256[] memory numbers = new uint256[](10);
    vm.roll(currentBlockNumber);
    for (uint256 i = 0; i < 10; i++) {
      bytes32 requestId = rng.requestRandomNumber();

      //   // simulate the time passing
      //   uint256 date = _getCurrentDate();
      //   vm.warp(date);

      // wait for 6 block because the request is for block.number + 5 and the blockhash is only available from the next block onwards
      vm.roll(block.number + 6);

      numbers[i] = rng.fullfillRandomNumber(requestId);

      if (i > 0) {
        // unlikely to fail
        assertNotEq(numbers[i], numbers[i - 1]);
      }
    }
  }

  function test_shouldFailWhenTryingToFillRandomnessTooEarly() public {
    bytes32 requestId = rng.requestRandomNumber();
    vm.expectRevert(
      abi.encodeWithSelector(
        SolrandLib.Solrand__TargetBlockHashNotYetAvailible.selector,
        1,
        6
      )
    );
    rng.fullfillRandomNumber(requestId);

    vm.roll(6);

    // still should fail as the blockhash is only available from the next block of the target block onwards
    vm.expectRevert(
      abi.encodeWithSelector(
        SolrandLib.Solrand__TargetBlockHashNotYetAvailible.selector,
        6,
        6
      )
    );
    rng.fullfillRandomNumber(requestId);
  }

  function test_BlockhashHistory() public {
    vm.roll(1000);
    assertNotEq(blockhash(block.number - 256), 0x0);
    assertEq(blockhash(block.number - 257), 0x0);
  }
}
