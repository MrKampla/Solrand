// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

import { SolrandConsumer } from "./Solrand.sol";

contract SolrandConsumerExample is SolrandConsumer {
  uint256 public number;

  /**
   * Request a random number from the Solrand library and wait at least 5 blocks for it to be
   * fullfillable.
   * @return requestId The ID of the request
   */
  function requestRandomNumber() public returns (bytes32 requestId) {
    return
      _requestRandomness(
        block.number + 5,
        abi.encodePacked("Counter", msg.sender)
      );
  }

  /**
   *
   * @param requestId The ID of the request to fullfill
   * @return The random number
   */
  function fullfillRandomNumber(bytes32 requestId) public returns (uint256) {
    bytes32 randomValue = _fullfillRandomness(requestId);
    number = uint256(randomValue);
    return number;
  }
}
