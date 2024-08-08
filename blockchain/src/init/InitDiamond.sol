// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { AppStorage, LibAppStorage } from "../libs/LibAppStorage.sol";

import { LibMersenneTwister } from "../libs/LibMersenneTwister.sol";

error DiamondAlreadyInitialized();

contract InitDiamond {
  event InitializeDiamond(address sender);

  function init() external {
    AppStorage storage s = LibAppStorage.diamondStorage();
    if (s.diamondInitialized) {
      revert DiamondAlreadyInitialized();
    }
    s.diamondInitialized = true;

    /*
        TODO: add custom initialization logic here
    */

    LibMersenneTwister.init(1);

    // emit DiamondInitialized(msg.sender);

    emit InitializeDiamond(msg.sender);
  }
}
