// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";
import { LibAppStorage } from "../libs/LibAppStorage.sol";

library LibDungeon {

    event AdventurerDamaged(address, uint256, uint256, string);
    event AdventurerKilled(address, uint256, string);

    function getAdventurerState(Adventurer calldata adventurer) internal view returns (AdventurerState memory adventurerState) {
        adventurerState = LibAppStorage.diamondStorage().adventurers[adventurer.tokenAddress][adventurer.tokenId];        
    }

    function getMonsterData(uint256 monsterId) internal view returns (MonsterData memory monsterData) {
        monsterData = LibAppStorage.diamondStorage().monsters[monsterId];
    }

    function getRoomData(address dungeon, uint256 roomId) internal view returns (RoomData memory roomData) {
        
    }

    function getRandomNumber() internal view returns (uint256) {
        return uint256(keccak256(abi.encode(block.prevrandao, block.timestamp))); //a lame random number
    }


    function checkSkill(uint256 adventurerSkill, uint256 targetSkill) internal view returns (bool) {
        
        //both roll a d20 and add them to their skill and compare the results
        return (adventurerSkill + getRandomNumber() % 20) > (targetSkill + getRandomNumber() % 20); 
    }

    //how much damage does this monster deal to the adventurer
    function calculateMonsterDamage(AdventurerState memory adventurerState, CombatStats memory combatStats, MonsterData memory monsterData) internal view returns (uint256) {
                
        if (combatStats.defense > monsterData.combatStats.attack) {
            return 1; // still grazes        
        }
        else
        {
            //simple calculation
            return (monsterData.combatStats.attack - combatStats.defense);
        }
    }

    function applyDamage(AdventurerState memory adventurerState, uint256 damage, string memory source) internal {
        
        if (damage > 0) {
            if (adventurerState.lifePoints > damage) {
                adventurerState.lifePoints -= damage;
                emit AdventurerDamaged(adventurerState, damage, adventurerState.lifePoints, source);
            } else {
                adventurerState.lifePoints = 0;
                emit AdventurerKilled(adventurerState, damage, source);
            }            
        }
    }


    function tickMonsters(RoomState memory roomState, AdventurerState memory adventurerState) internal 
    {        
        // all live monsters attack
        uint256 totalDamage = 0;
        for (uint256 i = 0; i < roomState.monsters.length; i++) {
            MonsterState memory monsterState = roomState.monsters[i];
            uint256 monsterId = monsterState.monsterId;
            if (monsterId > 0 && monsterState.lifePoints > 0) {        
                MonsterData memory monsterData = LibDungeon.getMonsterData(monsterId);
                //do a skill check
                if (!LibDungeon.checkSkill(adventurerState.combatStats.skill, monsterData.combatStats.skill)) {
                    //calculate damage
                    totalDamage += LibDungeon.calculateMonsterDamage(adventurerState, adventurerState.combatStats, monsterData);                                        
                }
            }
        }

        if (totalDamage > 0) {
            LibDungeon.applyDamage(adventurerState, totalDamage, "monsters");
        }
    }

}