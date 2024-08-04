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

  event TrapTriggered();



  // admin functions
  function createNewDungeon() external isAdmin returns (address)  {
    
    address dungeonAddress = address(new Dungeon(this));
    
    DungeonData storage t = LibAppStorage.diamondStorage().dungeons[dungeonAddress];
    t.status = DungeonStatus.Created;

    emit DungeonCreated(dungeonAddress);

    return dungeonAddress;
  }



  function addRooms(address dungeon, RoomData[] calldata rooms) external isAdmin {
    DungeonData storage dungeon = LibAppStorage.diamondStorage().dungeons[dungeon];
    for (uint256 i = 0; i < rooms.length; i++) {
      dungeon.rooms.push(rooms[i]);
    }
  }

  function modifyRoom(address dungeon, uint256 roomIdx, RoomData calldata room) external isAdmin {
    DungeonData storage dungeon = LibAppStorage.diamondStorage().dungeons[dungeon];
    dungeon.rooms[roomIdx] = room;
  }

  function getRoom(
    Adventurer calldata adventurer
  ) external view override returns (RoomState memory) {

    AdventurerState memory adv = LibDungeon.getAdventurerState(adventurer);
    if (adv.currentDungeon != msg.sender) {
      revert AdventurerNotInDungeon();
    }

    DungeonData storage dungeon = LibAppStorage.diamondStorage().dungeons[msg.sender];
    return dungeon.roomStates[adv.roomId];
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

    //is the caller the owner of the adventurer?
    //if (ERC721(adventurer.tokenAddress).ownerOf(adventurer.tokenId) != caller) {
    //  revert CallerIsNotTheOwner();
    //}


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

    //is the caller the owner of the adventurer?
    //if (ERC721(adventurer.tokenAddress).ownerOf(adventurer.tokenId) != caller) {
    //  revert CallerIsNotTheOwner();
    //}

    AdventurerState storage advState = LibAppStorage.diamondStorage().adventurers[adventurer.tokenAddress][adventurer.tokenId];

    if (advState.currentDungeon != msg.sender) {
        revert AdventurerNotInDungeon();
    }

    //adventurers can exit the dungeon at any time
    //as long as there are no live monsters in the room
    RoomState memory room = LibDungeon.getRoom(advState.currentDungeon, advState.roomId);

    for (uint256 i = 0; i < room.monsters.length; i++) {
      if (room.monsters[i].lifePoints > 0) {
        revert CantExitDungeonWithLiveMonsters();
      }
    }
    
    //allow the adventurer to exit the dungeon with items and xp if they are still alive
    LibDungeon.exitDungeon(adventurer, advState);
  }

  function nextRoom(
    address caller,
    Adventurer calldata adventurer,
    uint256 door
  ) external override {
    console2.log("nextRoom");

    //is the caller the owner of the adventurer?
    //if (ERC721(adventurer.tokenAddress).ownerOf(adventurer.tokenId) != caller) {
    //  revert CallerIsNotTheOwner();
    //}

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

    RoomState storage roomState = LibDungeon.getRoomState(advState.currentDungeon, advState.roomId);

    LibDungeon.tickMonsters(roomState, advState);

    // all live monsters attack    
    for (uint256 i = 0; i < roomState.monsters.length; i++) {
      MonsterState memory monsterState = roomState.monsters[i];
      uint256 monsterId = monsterState.monsterId;
      if (monsterId > 0 && monsterState.lifePoints > 0) {        
        MonsterData memory monsterData = LibDungeon.getMonster(monsterId);
        //do a skill check
        if (!LibDungeon.checkSkill(advState.combatStats.skill, monsterData.combatStats.skill)) {
            //take damage
            emit MonsterAttacked(advState.currentDungeon, advState.roomId, monsterData);
            LibDungeon.applyAdventurerDamageFromMonster(advState, advState.combatStats, monsterData);            
        }
      }
    }

    if (advState.lifePoints > 0) {

        //go to the next room
        advState.roomId = roomData.exits[door];

        //check for traps in the new room    
        RoomData memory newRoomData = LibDungeon.getRoomData(advState.currentDungeon, advState.roomId);
        if (newRoomData.trap > 0) {        
            TrapData memory trapData = LibDungeon.getTrapData(newRoomData.trap);
            TrapState storage trapState = LibDungeon.getTrapState(advState.currentDungeon, advState.roomId, trapData.trapId);
            //check if trap is armed
            if (block.timestamp > trapState.timestamp + trapData.cooldown) {
                if (!LibDungeon.checkSkill(advState.combatStats.skill, trapData.skill)) {
                    //take damage
                    emit TrapTriggered(advState.currentDungeon, advState.roomId, trapData.trapId);                
                    LibDungeon.applyAdventurerDamageFromTrap(advState, advState.combatStats, trapData);
                    trapState.timestamp = block.timestamp;
                }                            
            }            
        }
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