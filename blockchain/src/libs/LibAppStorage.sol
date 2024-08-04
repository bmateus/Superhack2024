// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";

struct AppStorage {
    bool diamondInitialized;
    uint256 reentrancyStatus;
    MetaTxContextStorage metaTxContext;

    mapping(address => ERC20Token) erc20s;

    mapping(address => mapping(uint256 => AdventurerState)) adventurers;
    mapping(address => bool) whitelistedAdventurerContracts;

    mapping(address => DungeonData) dungeons;

    mapping(address => Item) items; //make these ERC-1155s
    
    mapping (uint256 => MonsterData) monsters;

    mapping (uint256 => ChestData) chests;
    
    mapping (uint256 => TrapData) traps;

    mapping (uint256 => LootTable) lootTables;
    
    mapping (uint256 => Recipe) recipes;

    mapping (uint256 => CraftingStation) craftingStations;

    /*
    IMPORTANT NOTE!!!: Once contracts have been deployed you cannot modify the existing entries here. You can only append 
    new entries. Otherwise, any subsequent upgrades you perform will break the memory structure of your 
    deployed contracts.
    */

}

library LibAppStorage {
    bytes32 internal constant DIAMOND_APP_STORAGE_POSITION = keccak256("diamond.app.storage");

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = DIAMOND_APP_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
