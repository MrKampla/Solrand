// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

struct RandomnessRequest {
  uint256 requestBlockNumber;
  uint256 targetBlockNumber;
  uint256 nonce;
  bytes requesterIdentifier;
}

/**
 * This is a simple contract that requests a random number from the Solrand library.
 * WARNING: This randomness is not financially secure and should not be used in high-stakes applications.
 * It's perfect for games or low stakes apps where trying to cheat the system is not worth the effort.
 * @title SolrandConsumer
 * @author Kamil Planer <MrKampla>
 */
abstract contract SolrandConsumer {
  /// @custom:storage-location erc7201:solrand.main
  struct SolrandStorage {
    mapping(bytes32 => RandomnessRequest) requests;
    mapping(bytes => uint256) nonces;
    mapping(bytes32 => bytes32) randomValues;
  }

  // keccak256(abi.encode(uint256(keccak256('solrand.main')) - 1)) & ~bytes32(uint256(0xff));
  bytes32 private constant SOLRAND_STORAGE_LOCATION =
    0xb792d84204b94770d52d7e88daccf7d8ac63fd88b7fa0054f2b90489b8473000;

  function _getStorage() private pure returns (SolrandStorage storage $) {
    assembly {
      $.slot := SOLRAND_STORAGE_LOCATION
    }
  }

  function _requestRandomness(
    uint256 targetBlockNumber,
    bytes memory requesterIdentifier
  ) internal returns (bytes32 requestId) {
    SolrandStorage storage s = _getStorage();
    requestId = SolrandLib.requestRandomness(
      targetBlockNumber,
      s.nonces[requesterIdentifier],
      requesterIdentifier
    );
    s.requests[requestId] = RandomnessRequest({
      requestBlockNumber: block.number,
      targetBlockNumber: targetBlockNumber,
      nonce: s.nonces[requesterIdentifier],
      requesterIdentifier: requesterIdentifier
    });
    s.nonces[requesterIdentifier]++;
  }

  function _fullfillRandomness(bytes32 requestId) internal returns (bytes32) {
    SolrandStorage storage s = _getStorage();
    RandomnessRequest storage request = s.requests[requestId];
    bytes32 randomValue = SolrandLib.fullfillRandomness(
      request.requestBlockNumber,
      request.targetBlockNumber,
      request.nonce,
      request.requesterIdentifier
    );
    s.randomValues[requestId] = randomValue;
    return randomValue;
  }
}

uint256 constant MAX_BLOCKHASH_HISTORY = 255;

library SolrandLib {
  error Solrand__TargetBlockHashNotYetAvailible(
    uint256 currentBlockNumber,
    uint256 targetBlockNumber
  );

  error Solrand__TargetBlockHashExpired(uint256 blocksAgo);

  function requestRandomness(
    RandomnessRequest memory request
  ) public view returns (bytes32 requestId) {
    return
      requestRandomness(
        request.targetBlockNumber,
        request.nonce,
        request.requesterIdentifier
      );
  }

  function requestRandomness(
    uint256 targetBlockNumber,
    uint256 nonce,
    bytes memory requesterIdentifier
  ) public view returns (bytes32 requestId) {
    return
      keccak256(
        abi.encodePacked(
          "SolrandRequestV1",
          block.number,
          targetBlockNumber,
          nonce,
          requesterIdentifier
        )
      );
  }

  function fullfillRandomness(
    RandomnessRequest memory request
  ) public view returns (bytes32 randomValue) {
    return
      fullfillRandomness(
        request.requestBlockNumber,
        request.targetBlockNumber,
        request.nonce,
        request.requesterIdentifier
      );
  }

  function fullfillRandomness(
    uint256 requestBlockNumber,
    uint256 targetBlockNumber,
    uint256 nonce,
    bytes memory requesterIdentifier
  ) public view returns (bytes32 randomValue) {
    if (block.number <= targetBlockNumber) {
      revert Solrand__TargetBlockHashNotYetAvailible(
        block.number,
        targetBlockNumber
      );
    }
    if (block.number > targetBlockNumber + MAX_BLOCKHASH_HISTORY) {
      revert Solrand__TargetBlockHashExpired(block.number - targetBlockNumber);
    }

    return
      keccak256(
        abi.encodePacked(
          requestBlockNumber,
          blockhash(targetBlockNumber),
          nonce,
          requesterIdentifier
        )
      );
  }
}
