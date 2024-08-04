// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "forge-std/Test.sol";
import { TestBaseContract, console2 } from "./utils/TestBaseContract.sol";
import { Dungeon } from "../../src/facades/Dungeon.sol";
import { DungeonData, RoomData, TrapData, MonsterData, ChestData, Adventurer } from "../../src/shared/Structs.sol";

contract DungeonTest is TestBaseContract {
  function setUp() public virtual override {
    super.setUp();
  }

  function getRooms() internal pure returns (RoomData[] memory) {
    
    RoomData[] memory rooms = new RoomData[](3);
    rooms[0] = RoomData({
        exits: [uint256(1), 2, 0, 0],
        trap: 0,
        monsters: [uint256(0), 0, 0, 0],
        chests: [uint256(0), 0],
        craftingStation: 0,
        hasFire: false        
      });
    rooms[1] = RoomData({
        exits: [uint256(1), 2, 0, 0],
        trap: 0,
        monsters: [uint256(0), 0, 0, 0],
        chests: [uint256(0), 0],
        craftingStation: 0,
        hasFire: false        
      });
    rooms[2] = RoomData({
        exits: [uint256(1), 2, 0, 0],
        trap: 0,
        monsters: [uint256(0), 0, 0, 0],
        chests: [uint256(0), 0],
        craftingStation: 0,
        hasFire: false        
      });
    return rooms;
  }


  function testDeploy() public returns (Dungeon) {
    
    address addr = diamond.createNewDungeon();
    Dungeon dungeon = Dungeon(addr);
    return dungeon;

  }

  function testEnterDungeon() public {
    Dungeon dungeon = testDeploy();

    Adventurer memory adv = Adventurer({
      tokenAddress: 0x3Bf8DE5512871ca5f74b9c14CC6cf19a316F1AA4, //an arbitrary whitelisted token
      tokenId: 1
    });

    dungeon.enterDungeon(adv);

  }

}
