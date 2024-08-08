// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";
import { LibAppStorage } from "../libs/LibAppStorage.sol";
import { IERC721 } from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { IERC165 } from "lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol";

import { console2 } from "forge-std/console2.sol";

library LibDungeon {

    event AdventurerDamaged(Adventurer, uint256, uint256, string);
    event AdventurerKilled(Adventurer, uint256, string);

    event TrapTriggered(address dungeon, uint256 roomId, uint256 trapId);

    error CallerIsNotTheOwner();
    error AdventurerNotWhitelisted(address);

    function checkAdventurer(address caller, Adventurer calldata adventurer) internal view {

        if (adventurer.tokenAddress == 0x3Bf8DE5512871ca5f74b9c14CC6cf19a316F1AA4 ) {
            return;
        }

        //check that it is whitelisted
        if (!LibAppStorage.diamondStorage().whitelistedAdventurerContracts[adventurer.tokenAddress]) {
            revert AdventurerNotWhitelisted(adventurer.tokenAddress);
        }

        //is it an ERC721 or a ERC1155?
        //if ( IERC165(adventurer.tokenAddress).supportsInterface(type(IERC721).interfaceId) ) {
            //is the caller the owner of the adventurer?
            if (IERC721(adventurer.tokenAddress).ownerOf(adventurer.tokenId) != caller) {
                revert CallerIsNotTheOwner();
            }    
        //}        
    }

    function getMonsterData(uint256 monsterId) internal view returns (MonsterData memory monsterData) {
        monsterData = LibAppStorage.diamondStorage().monsters[monsterId];
    }

    function getRoomData(address dungeon, uint256 roomId) internal view returns (RoomData memory roomData) {
        roomData = LibAppStorage.diamondStorage().rooms[address(dungeon)][roomId];
    }

    function getRoomState(address dungeon, uint256 roomId) internal view returns (RoomState storage roomState) {
        roomState = LibAppStorage.diamondStorage().roomStates[address(dungeon)][roomId];
    }

    function getTrapData(uint256 trapId) internal view returns (TrapData memory trapData) {
        trapData = LibAppStorage.diamondStorage().traps[trapId];
    }

    function getRandomNumber() internal view returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encode(block.prevrandao, block.timestamp)));
        console2.log("random number: ", randomNumber);
        return randomNumber; //a lame random number
    }


    function checkSkill(uint256 adventurerSkill, uint256 targetSkill) internal view returns (bool) {
        
        //both roll a d20 and add them to their skill and compare the results
        return (adventurerSkill + getRandomNumber() % 20) > (targetSkill + getRandomNumber() % 20); 
    }

    //how much damage does this monster deal to the adventurer
    function calculateMonsterDamage(AdventurerState memory adventurerState, MonsterData memory monsterData) internal pure returns (uint256) {
                
        if (adventurerState.combatStats.defense > monsterData.combatStats.attack) {
            return 1; // still grazes        
        }
        else
        {
            //simple calculation
            return (monsterData.combatStats.attack - adventurerState.combatStats.defense);
        }
    }

    function calculateTrapDamage(AdventurerState memory adventurerState, TrapData memory trapData) internal pure returns (uint256) {
        uint256 def = adventurerState.combatStats.defense / 2;
        if (def > trapData.damage) {
            return 1; // still grazes
        }
        else
        {
            //simple calculation
            return (trapData.damage - def);
        }                 
    }

    function applyDamage(AdventurerState storage adventurerState, uint256 damage, string memory source) internal {
        
        if (damage > 0) {
            if (adventurerState.hitPoints > damage) {
                adventurerState.hitPoints -= damage;
                emit AdventurerDamaged(adventurerState.adventurer, damage, adventurerState.hitPoints, source);
            } else {
                adventurerState.hitPoints = 0;
                emit AdventurerKilled(adventurerState.adventurer, damage, source);
            }            
        }
    }


    function tickMonsters(AdventurerState storage adventurerState) internal 
    {   
        RoomState memory roomState = LibAppStorage.diamondStorage().roomStates[adventurerState.currentDungeon][adventurerState.roomId];

        // all live monsters attack
        uint256 totalDamage = 0;
        for (uint256 i = 0; i < roomState.monsterStates.length; i++) {
            MonsterState memory monsterState = roomState.monsterStates[i];
            uint256 monsterId = monsterState.id;
            if (monsterId > 0 && monsterState.hitPoints > 0) {        
                MonsterData memory monsterData = LibDungeon.getMonsterData(monsterId);
                //do a skill check
                if (!LibDungeon.checkSkill(adventurerState.combatStats.skill, monsterData.combatStats.skill)) {
                    //calculate damage
                    totalDamage += LibDungeon.calculateMonsterDamage(adventurerState, monsterData);                                        
                }
                else
                {
                    console2.log("monster missed");
                }
            }
        }

        if (totalDamage > 0) {
            LibDungeon.applyDamage(adventurerState, totalDamage, "monsters");
        }
    }

    function tickTraps(AdventurerState storage adventurerState) internal {
        
        RoomData memory roomData = LibDungeon.getRoomData(adventurerState.currentDungeon, adventurerState.roomId);
        if (roomData.trap > 0) {        
            TrapData memory trapData = LibDungeon.getTrapData(roomData.trap);
            RoomState storage newRoomState = LibDungeon.getRoomState(adventurerState.currentDungeon, adventurerState.roomId);
            //check if trap is armed
            if (block.timestamp > newRoomState.trapState.timestamp + trapData.cooldown) {
                if (!LibDungeon.checkSkill(adventurerState.combatStats.skill, trapData.skill)) {
                    //take damage
                    emit TrapTriggered(adventurerState.currentDungeon, adventurerState.roomId, trapData.id);                
                    uint256 trapDamage = LibDungeon.calculateTrapDamage(adventurerState, trapData);
                    if (trapDamage > 0) {
                      LibDungeon.applyDamage(adventurerState, trapDamage, "trap");
                    }
                    newRoomState.trapState.timestamp = block.timestamp;
                }                            
            }            
        }
    }

    function exitDungeon(AdventurerState storage adventurerState) internal {
        
        if (adventurerState.hitPoints > 0) {

            // allow the adventurer to exit the dungeon with items and xp
            
            //add xp
            adventurerState.claimableXp += adventurerState.xp;
            adventurerState.xp = 0;

            //transfer items to adventurer owner
            //TODO

        }

        //clear out current dungeon
        adventurerState.currentDungeon = address(0);
        adventurerState.roomId = 0;
        
    }


}