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
error DungeonNotReady();


contract DungeonFacet is IDungeonFacet, AccessControl {

  /**
   * @dev Emitted when a new dungeon is deployed.
   */
  event DungeonCreated(address dungeon);

  event MonsterAttacked();

  error InvalidMonster(uint256);
  error InvalidChest(uint256);


  // admin functions
  function createNewDungeon(uint256 startingRoom) external isAdmin returns (address)  {
    
    address dungeonAddress = address(new Dungeon(this));
    
    DungeonData storage t = LibAppStorage.diamondStorage().dungeons[dungeonAddress];
    t.status = DungeonStatus.Created;
    t.startingRoom = startingRoom;

    emit DungeonCreated(dungeonAddress);

    return dungeonAddress;
  }

  function updateRooms(address dungeon, RoomData[] calldata rooms) external isAdmin {
  
    for (uint256 i = 0; i < rooms.length; i++) {

      RoomData memory room = rooms[i];
      uint256 roomId = room.id;
      LibAppStorage.diamondStorage().rooms[dungeon][roomId] = room;

      RoomState storage roomState = LibAppStorage.diamondStorage().roomStates[dungeon][roomId];

      roomState.id = roomId;

      //roomState.monsterStates = new MonsterState[](room.monsters.length); //not allowed?
      delete roomState.monsterStates;
      for (uint256 j = 0; j < room.monsters.length; j++) {
        uint256 monsterId = room.monsters[j];

        if (monsterId == 0)
          continue;        

        MonsterData memory monsterData = LibAppStorage.diamondStorage().monsters[monsterId];
        
        //is it valid?
        if (monsterData.id == 0) {
          revert InvalidMonster(monsterId);
        }

        roomState.monsterStates.push(MonsterState({
          id: monsterId,
          hitPoints: monsterData.hitPoints,
          timestamp: block.timestamp
        }));                
      }

      //roomState.chestStates = new ChestState[](room.chests.length); //not allowed?
      delete roomState.chestStates;
      for (uint256 j = 0; j < room.chests.length; j++) {
        uint256 chestId = room.chests[j];

        if (chestId == 0)
          continue;

        ChestData memory chestData = LibAppStorage.diamondStorage().chests[chestId];
        //is it valid?
        if (chestData.id == 0) {
          revert InvalidChest(chestId);
        }

        roomState.chestStates.push(ChestState({
          id: chestId,
          locked: chestData.locked,
          armed: chestData.trapped,
          timestamp: 0
        }));
        
      }

      roomState.trapState = TrapState({
        id: room.trap,
        timestamp: 0
      });
    }
  }

  function updateMonsters(MonsterData[] calldata monsters) external isAdmin {
    for (uint256 i = 0; i < monsters.length; i++) {
      MonsterData memory monster = monsters[i];
      LibAppStorage.diamondStorage().monsters[monster.id] = monster;
    }
  }

  function whitelistAdventurerToken(address token) external isAdmin {

    LibAppStorage.diamondStorage().whitelistedAdventurerContracts[token] = true;
    
  }

  function setDungeonState(address dungeon, DungeonStatus status) external isAdmin {
    LibAppStorage.diamondStorage().dungeons[dungeon].status = status;
  }

  function getRoomDataById(address dungeon, uint256 roomId) external view returns (RoomData memory roomData)
  {
    roomData = LibAppStorage.diamondStorage().rooms[dungeon][roomId];
  }

  function getRoomStateById(address dungeon, uint256 roomId) external view returns (RoomState memory roomState)
  {
    roomState = LibAppStorage.diamondStorage().roomStates[dungeon][roomId];
  }


  function getRoom(
    Adventurer calldata adventurer
  ) external view override returns (RoomState memory roomState) {

    AdventurerState memory adv = LibAppStorage.diamondStorage().adventurers[adventurer.tokenAddress][adventurer.tokenId];
    if (adv.currentDungeon != msg.sender) {
      revert AdventurerNotInDungeon();
    }

    roomState = LibAppStorage.diamondStorage().roomStates[adv.currentDungeon][adv.roomId];
  }

  function getAdventurerState(
    Adventurer calldata adventurer
  ) external view override returns (AdventurerState memory adventurerState) {    
    adventurerState = LibAppStorage.diamondStorage().adventurers[adventurer.tokenAddress][adventurer.tokenId];
  }


  function enterDungeon(address caller, Adventurer calldata adventurer) external override {

    console2.log("entering dungeon");

    LibDungeon.checkAdventurer(caller, adventurer);
    
    AdventurerState storage advState = LibAppStorage.diamondStorage().adventurers[adventurer.tokenAddress][adventurer.tokenId];

    advState.adventurer = adventurer;
    
    //is the adventurer already in a dungeon?
    if (advState.currentDungeon != address(0)) {
      revert AdventurerAlreadyInDungeon();
    }

    //check the adventurer's equipment
    //TODO

    DungeonData storage dungeon = LibAppStorage.diamondStorage().dungeons[msg.sender];
    if (dungeon.status != DungeonStatus.Ready) {
      revert DungeonNotReady();
    }

    console2.log("adventurer:", adventurer.tokenAddress, adventurer.tokenId);
    console2.log("starting room", dungeon.startingRoom);

    advState.currentDungeon = msg.sender;
    advState.roomId = dungeon.startingRoom;
    //advState.seed = getRandomSeed();
    
    //just some default stats for now
    //TODO: modify stats based on equipment 
    advState.hitPoints = 100;
    advState.combatStats.attack = 10;
    advState.combatStats.defense = 10;
    advState.combatStats.speed = 10;
    advState.combatStats.skill = 10;

    advState.xp = 0;

    //ready to go!
  }

  function exitDungeon(address caller, Adventurer calldata adventurer) external override {

    console2.log("exiting dungeon");

    LibDungeon.checkAdventurer(caller, adventurer);
    
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

    LibDungeon.checkAdventurer(caller, adventurer);
    
    AdventurerState storage advState = LibAppStorage.diamondStorage().adventurers[adventurer.tokenAddress][adventurer.tokenId];

    if (advState.currentDungeon != msg.sender) {
        revert AdventurerNotInDungeon();
    }

    if (advState.hitPoints == 0) {
        revert AdventurerIsDead();
    }

    RoomData memory roomData = LibDungeon.getRoomData(advState.currentDungeon, advState.roomId);

    uint256 nextRoomId = roomData.exits[door];
    //check if this is a valid exit
    if (nextRoomId == 0) {
        revert InvalidExit();
    }

    console2.log("ticking monsters");
    LibDungeon.tickMonsters(advState);

    if (advState.hitPoints > 0) {

        //go to the next room
        advState.roomId = nextRoomId;
        //check for traps in the new room    
        console2.log("ticking traps in new room");
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