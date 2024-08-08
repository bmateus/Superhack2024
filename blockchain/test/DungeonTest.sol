// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "forge-std/Test.sol";
import { TestBaseContract, console2 } from "./utils/TestBaseContract.sol";
import { Dungeon } from "../../src/facades/Dungeon.sol";
import  "../../src/shared/Structs.sol";
import { AdventurerNotInDungeon } from "../../src/facets/DungeonFacet.sol";


contract DungeonTest is TestBaseContract {

  function setUp() public virtual override {
    super.setUp();
  }

  function getMonsters() internal pure returns (MonsterData[] memory) {

    MonsterData[] memory monsters = new MonsterData[](3);
    monsters[0] = MonsterData({
        id: 1,
        hitPoints: 1,
        combatStats: CombatStats({
          attack: 1,
          defense: 1,
          speed: 1,
          skill: 1
        }),
        lootTableId: 0
      });
    monsters[1] = MonsterData({
        id: 2,
        hitPoints: 10,
        combatStats: CombatStats({
          attack: 3,
          defense: 3,
          speed: 3,
          skill: 3
        }),
        lootTableId: 0
      });
    monsters[2] = MonsterData({
        id: 3,
        hitPoints: 20,
        combatStats: CombatStats({
          attack: 7,
          defense: 7,
          speed: 7,
          skill: 7
        }),
        lootTableId: 0
      });
    return monsters;
  }

  function getRooms() internal pure returns (RoomData[] memory) {
    
    RoomData[] memory rooms = new RoomData[](3);
    rooms[0] = RoomData({
        id: 1,
        exits: [uint256(2), 3, 0, 0],
        trap: 0,
        monsters: [uint256(1), 0, 0, 0],
        chests: [uint256(0), 0],
        craftingStation: 0,
        hasFire: false        
      });
    rooms[1] = RoomData({
        id: 2,
        exits: [uint256(1), 0, 0, 0],
        trap: 0,
        monsters: [uint256(0), 0, 0, 0],
        chests: [uint256(0), 0],
        craftingStation: 0,
        hasFire: false        
      });
    rooms[2] = RoomData({
        id: 3,
        exits: [uint256(1), 0, 0, 0],
        trap: 0,
        monsters: [uint256(0), 0, 0, 0],
        chests: [uint256(0), 0],
        craftingStation: 0,
        hasFire: false        
      });
    return rooms;
  }

  function getTestAdventurer() internal pure returns (Adventurer memory) {

    return Adventurer({
      tokenAddress: 0x3Bf8DE5512871ca5f74b9c14CC6cf19a316F1AA4, //an arbitrary whitelisted token
      tokenId: 1
    });
  }


  function printAdventurerState(AdventurerState memory advState) internal {
    console2.log("AdventurerState for tokenId: ", advState.adventurer.tokenAddress, advState.adventurer.tokenId);    
    console2.log(">> currentDungeon: ", advState.currentDungeon);
    console2.log(">> roomId: ", advState.roomId);
    console2.log(">> life: ", advState.hitPoints);
  }

  function printRoomData(RoomData memory roomData) internal {

    console2.log("RoomData for id: ", roomData.id);
    console2.log("exit 0: ", roomData.exits[0]);
    console2.log("trap: ", roomData.trap);
    console2.log("monster 0: ", roomData.monsters[0]);
    console2.log("chest 0: ", roomData.chests[0]);
    console2.log("craftingStation: ", roomData.craftingStation);
    console2.log("hasFire: ", roomData.hasFire);
  } 

  function printRoomState(RoomState memory roomState) internal {
  
    console2.log("RoomState for id: ", roomState.id);
    //printMonsterState(roomState.monsterStates[0]);
    //printChestState(roomState.chestStates[0]);
    //printTrapState(roomState.trapState);
  }

  function testDeploy() public returns (Dungeon) {
    
    diamond.updateMonsters(getMonsters());

    address addr = diamond.createNewDungeon(1);
    Dungeon dungeon = Dungeon(addr);

    diamond.whitelistAdventurerToken(0x3Bf8DE5512871ca5f74b9c14CC6cf19a316F1AA4);

    diamond.updateRooms(addr, getRooms());

    //RoomData memory roomData = diamond.getRoomDataById(addr, 1);
    //printRoomData(roomData);

    //RoomState memory roomState = diamond.getRoomStateById(addr, 1);
    //printRoomState(roomState);

    diamond.setDungeonState(addr, DungeonStatus.Ready);

    return dungeon;

  }

  


  function testExitDungeonRevert() public {

    Dungeon dungeon = testDeploy();

    Adventurer memory adv = getTestAdventurer();

    vm.expectRevert(abi.encodePacked(AdventurerNotInDungeon.selector));
    dungeon.exitDungeon(adv);

  }

  function testEnterDungeon() public {
    Dungeon dungeon = testDeploy();

    Adventurer memory adv = getTestAdventurer();

    dungeon.enterDungeon(adv);
  }

  function testNextRoom() public {

    Dungeon dungeon = testDeploy();
    Adventurer memory adv = getTestAdventurer();
    dungeon.enterDungeon(adv);
    dungeon.nextRoom(adv, 0);

    AdventurerState memory advState = dungeon.getAdventurerState(adv);

    printAdventurerState(advState);

    assertEq(advState.roomId, 2, "Wrong room!");
  }

}
