// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { IDungeonFacet } from "../interfaces/IDungeonFacet.sol";
import { MetaContext } from "../shared/MetaContext.sol";
import { Adventurer, RoomState, AdventurerState, RoomData } from "../shared/Structs.sol";

// A dungeon is a map that contains a list of rooms that can be explored by Adventurers
// a dungeon keeps track of all the players that are currently in it
// an adventurer can only be in one dungeon at a time
contract Dungeon is MetaContext {

    /**
     * @dev The parent Diamond that implements the business logic.
     */
    IDungeonFacet private _parent;

    /**
     * @dev Constructor.
     *
     * @param parent The parent Diamond that implements the business logic.
     */
    constructor(IDungeonFacet parent) {
        _parent = parent;
    }

    // Player Interface

    // allows a player to enter the dungeon by specifying who the adventurer being used is
    // after meeting all the pre-requisites
    // i.e. paying any fees or posessing all the items required to enter this dungeon
    // and also specifying all the items that the player is carrying into the dungeon
    function enterDungeon(Adventurer calldata adventurer) public {
        address caller = _msgSender();
        _parent.enterDungeon(caller, adventurer);
    }

    // gets the state of the current room in the dungeon
    function getRoom(Adventurer calldata adventurer) public view returns (RoomState memory roomState) {
        _parent.getRoom(adventurer);
    }

    // gets the state of the given adventurer in the dungeon 
    function getAdventurerState(Adventurer calldata adventurer) public view returns (AdventurerState memory adventurerState) {
        _parent.getAdventurerState(adventurer);
    }

    // exits the dungeon, awarding any loot and xp if the player is still alive
    // if you die, items brought into the dungeon will be lost - they get recycled back into the loot pool
    // (i.e. someone else might come in and find it)
    function exitDungeon(Adventurer calldata adventurer) public {
        address caller = _msgSender();
        _parent.exitDungeon(caller, adventurer);
    }

    //perform dungeon actions:

    //pick an exit 
    //- there is an chance that this action will fail (like if a monster is alive), which can trigger events which may modify the player's state
    //- upon entering the next room, an event can trigger which may modify the player's state
    function nextRoom(Adventurer calldata adventurer, uint256 door) public
    {
        address caller = _msgSender();
        _parent.nextRoom(caller, adventurer, door);
    }

    // attempt to fight a monster
    function fightMonster(Adventurer calldata adventurer, uint256 monster) public
    {
        address caller = _msgSender();
        _parent.fightMonster(caller, adventurer, monster);
    }

    // attempt to use an item in the player's inventory
    function useItem(Adventurer calldata adventurer, uint256 item) public
    {
        address caller = _msgSender();
        _parent.useItem(caller, adventurer, item);
    }

    // attempt to craft something
    function useCraftingStation(Adventurer calldata adventurer, uint256 station, uint256 recipe) public
    {
        address caller = _msgSender();
        _parent.useCraftingStation(caller, adventurer, station, recipe);
    }

    // attempt to open a chest
    function openChest(Adventurer calldata adventurer, uint256 chest) public
    {
        address caller = _msgSender();
        _parent.openChest(caller, adventurer, chest);
    }

    // attempt to warm a potato
    function warmPotato(Adventurer calldata adventurer) public
    {
        address caller = _msgSender();
        _parent.warmPotato(caller, adventurer);
    }

    // attempt to throw a potato at another player in the room
    function throwPotato(Adventurer calldata adventurer, uint256 target) public
    {
        address caller = _msgSender();
        _parent.throwPotato(caller, adventurer, target);
    }

}