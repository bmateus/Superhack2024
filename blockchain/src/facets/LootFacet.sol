// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { AccessControl } from "../shared/AccessControl.sol";
import { LootTable, LootResult } from "../shared/Structs.sol";

// The LootFacet contains the behaviour for pulling on a Loot Table and generating / minting new Items

contract LootFacet is AccessControl {

    event LootCreated();

    function loot(LootTable calldata lootTable, uint256 amount) external returns (LootResult[] memory lootResults) {

    }

    function createLootTable(LootTable calldata lootTable) external isAdmin {

    }

}