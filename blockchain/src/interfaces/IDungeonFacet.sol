// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";

/**
 * @dev Dungeon diamond facet interface.
 */
interface IDungeonFacet {

    //admin edit function

    function createNewDungeon() external returns (address);

    function addRooms(address dungeon, RoomData[] calldata rooms) external;

    function modifyRoom(address dungeon, uint256 roomIdx, RoomData calldata room) external;

    // player actions:

    function enterDungeon(address caller, Adventurer calldata adventurer) external;

    function getRoom(Adventurer calldata adventurer) external view returns (RoomState memory roomState);

    function getAdventurerState(Adventurer calldata adventurer) external view returns (AdventurerState memory adventurerState);

    function exitDungeon(address caller,Adventurer calldata adventurer) external;

    function nextRoom(address caller, Adventurer calldata adventurer, uint256 door) external;
    
    function fightMonster(address caller, Adventurer calldata adventurer, uint256 monster) external;
    
    function useItem(address caller, Adventurer calldata adventurer, uint256 item) external;

    function useCraftingStation(address caller, Adventurer calldata adventurer, uint256 station, uint256 recipe) external;

    function openChest(address caller, Adventurer calldata adventurer, uint256 chest) external;

    function warmPotato(address caller, Adventurer calldata adventurer) external;
    
    function throwPotato(address caller, Adventurer calldata adventurer, uint256 target) external;

}