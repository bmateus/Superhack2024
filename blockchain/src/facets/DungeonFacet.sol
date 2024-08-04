// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { Dungeon } from "../facades/Dungeon.sol";
import { IDungeonFacet } from "../interfaces/IDungeonFacet.sol";
import { AccessControl } from "../shared/AccessControl.sol";
import { LibAppStorage } from "../libs/LibAppStorage.sol";
import { LibDungeon } from "../libs/LibDungeon.sol";
import "../shared/Structs.sol";

import { console2 } from "forge-std/console2.sol";

error AdventurerNotInDungeon();
error AdventurerAlreadyInDungeon();
error AdventurerIsDead();
error InvalidExit();


contract DungeonFacet is IDungeonFacet, AccessControl {

  /**
   * @dev Emitted when a new dungeon is deployed.
   */
  event DungeonCreated(address dungeon);

  event MonsterAttacked();

  error InvalidMonster(uint256);
  error InvalidChest(uint256);


  // admin functions
  function createNewDungeon() external isAdmin returns (address)  {
    
    address dungeonAddress = address(new Dungeon(this));
    
    DungeonData storage t = LibAppStorage.diamondStorage().dungeons[dungeonAddress];
    t.status = DungeonStatus.Created;

    emit DungeonCreated(dungeonAddress);

    return dungeonAddress;
  }



  function addRooms(address dungeon, RoomData[] calldata rooms) external isAdmin {
  
    for (uint256 i = 0; i < rooms.length; i++) {

      RoomData memory room = rooms[i];
      uint256 roomId = room.id;
      LibAppStorage.diamondStorage().rooms[dungeon][roomId] = room;

      MonsterState[] memory monsterStates = new MonsterState[](room.monsters.length);
      for (uint256 j = 0; j < room.monsters.length; j++) {
        uint256 monsterId = room.monsters[j];
        MonsterData memory monsterData = LibAppStorage.diamondStorage().monsters[monsterId];
        //is it valid?
        if (monsterData.id == 0) {
          revert InvalidMonster(monsterId);
        }
        monsterStates[j] = MonsterState({
          id: monsterId,
          lifePoints: monsterData.lifePoints,
          timestamp: block.timestamp
        });
      }

      ChestState[] memory chestStates = new ChestState[](room.chests.length);
      for (uint256 j = 0; j < room.chests.length; j++) {
        uint256 chestId = room.chests[j];
        ChestData memory chestData = LibAppStorage.diamondStorage().chests[chestId];
        //is it valid?
        if (chestData.id == 0) {
          revert InvalidChest(chestId);
        }
        chestStates[j] = ChestState({
          id: chestId,
          locked: chestData.locked,
          armed: chestData.trapped,          
          timestamp: 0
        });
      }

      TrapState memory trapState = TrapState({
        id: room.trap,
        timestamp: 0
      });

      LibAppStorage.diamondStorage().roomStates[dungeon][roomId] = RoomState({
          id: roomId,
          monsterStates: monsterStates,
          chestStates: chestStates,
          trapState: trapState
      });
    }
  }

  function modifyRoom(address dungeon, uint256 roomId, RoomData calldata room) external isAdmin {
    LibAppStorage.diamondStorage().rooms[dungeon][roomId] = room;
    //TODO: update room state
  }

  function getRoom(
    Adventurer calldata adventurer
  ) external view override returns (RoomState memory roomState) {

    AdventurerState memory adv = LibDungeon.getAdventurerState(adventurer);
    if (adv.currentDungeon != msg.sender) {
      revert AdventurerNotInDungeon();
    }

    roomState = LibAppStorage.diamondStorage().roomStates[adv.currentDungeon][adv.roomId];
  }

  function getAdventurerState(
    Adventurer calldata adventurer
  ) external view override returns (AdventurerState memory) {
    
    AdventurerState memory adv = LibDungeon.getAdventurerState(adventurer);
    if (adv.currentDungeon != msg.sender) {
      revert AdventurerNotInDungeon();
    }

    return adv;
  }


  function enterDungeon(address caller, Adventurer calldata adventurer) external override {

    console2.log("entering dungeon");

    LibDungeon.checkAdventurerOwnership(caller, adventurer);
    
    AdventurerState storage advState = LibAppStorage.diamondStorage().adventurers[adventurer.tokenAddress][adventurer.tokenId];
    
    //is the adventurer already in a dungeon?
    if (advState.currentDungeon != address(0)) {
      revert AdventurerAlreadyInDungeon();
    }

    //check the adventurer's equipment
    //TODO


    advState.currentDungeon = msg.sender;
    advState.roomId = 1;
    //advState.seed = getRandomSeed();
    
    //just some default stats for now
    //TODO: modify stats based on equipment 
    advState.lifePoints = 100;
    advState.combatStats.attack = 10;
    advState.combatStats.defense = 10;
    advState.combatStats.speed = 10;
    advState.combatStats.skill = 10;

    advState.xp = 0;

    //ready to go!
  }

  function exitDungeon(address caller, Adventurer calldata adventurer) external override {

    console2.log("exiting dungeon");

    LibDungeon.checkAdventurerOwnership(caller, adventurer);
    
    AdventurerState storage advState = LibAppStorage.diamondStorage().adventurers[adventurer.tokenAddress][adventurer.tokenId];

    if (advState.currentDungeon != msg.sender) {
        revert AdventurerNotInDungeon();
    }

    // adventurers can exit the dungeon at any time 
    
    // monsters will however get an attack if they are alive
    LibDungeon.tickMonsters(advState);
    
    // allow the adventurer to exit the dungeon (with items and xp if they are still alive)
    LibDungeon.exitDungeon(advState);

  }

  function nextRoom(
    address caller,
    Adventurer calldata adventurer,
    uint256 door
  ) external override {
    console2.log("nextRoom");

    LibDungeon.checkAdventurerOwnership(caller, adventurer);
    
    AdventurerState storage advState = LibAppStorage.diamondStorage().adventurers[adventurer.tokenAddress][adventurer.tokenId];

    if (advState.currentDungeon != msg.sender) {
        revert AdventurerNotInDungeon();
    }

    if (advState.lifePoints == 0) {
        revert AdventurerIsDead();
    }

    RoomData memory roomData = LibDungeon.getRoomData(advState.currentDungeon, advState.roomId);
    //check if this is a valid exit
    if (roomData.exits[door] == 0) {
        revert InvalidExit();
    }

    LibDungeon.tickMonsters(advState);

    if (advState.lifePoints > 0) {

        //go to the next room
        advState.roomId = roomData.exits[door];
        //check for traps in the new room    
        LibDungeon.tickTraps(advState);
    }

  }

  function fightMonster(
    address caller,
    Adventurer calldata adventurer,
    uint256 monster
  ) external override {
    console2.log("fightMonster");



  }

  function useItem(
    address caller,
    Adventurer calldata adventurer,
    uint256 item
  ) external override {
    console2.log("useItem");
  }

  function useCraftingStation(
    address caller,
    Adventurer calldata adventurer,
    uint256 station,
    uint256 recipe
  ) external override {
    console2.log("useCraftingStation");
  }

  function openChest(
    address caller,
    Adventurer calldata adventurer,
    uint256 chest
  ) external override {
    console2.log("openChest");
  }

  function warmPotato(address caller, Adventurer calldata adventurer) external override {
    console2.log("warmPotato");



  }

  function throwPotato(
    address caller,
    Adventurer calldata adventurer,
    uint256 target
  ) external override {
    console2.log("throwPotato");
  }

}