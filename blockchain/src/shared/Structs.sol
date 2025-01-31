// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

struct MetaTxContextStorage {
  address trustedForwarder;
}

struct ERC20Token {
  string name;
  string symbol;
  uint8 decimals;
  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowances;
  uint256 totalSupply;
}

struct ERC20TokenConfig {
  string name;
  string symbol;
  uint8 decimals;
}

struct ERC1155Token {
  string name;
}

struct ERC1155TokenConfig {
  string name;
  string symbol;
}




struct Item {
  address tokenAddr;
  uint256 tokenId;
  uint256 amount; //always 1 if ERC-721; otherwise the number of items if ERC-1155
}

// a loot table represents a list of items that can be randomly selected
struct LootTable
{
  uint256 id;
  Item[] items;
  uint256[] probabilities;
  uint256 totalProbability;
}

struct LootResult
{
  address item;
  uint256 tokenId;
  uint256 amount; //always 1 if ERC-721; otherwise the number of items if ERC-1155
}

// a recipe has a list of input items and a list of possible output items
// the can be a chance to craft multiple outputs based on probability
struct Recipe
{
  Item[] ingredients;
  LootTable lootTable;
}

struct CraftingStation
{
  uint256[] recipes;
}

struct DungeonRequirements
{
  address token;
  uint256 tokenAmount;  
}

enum DungeonStatus {
  Invalid,
  Created,
  Ready
}

struct DungeonData {
  DungeonStatus status;
  uint256 startingRoom;
  DungeonRequirements[] requirements;
}

struct RoomData {
  uint256 id;
  uint256[4] exits;  
  uint256[4] monsters;
  uint256[2] chests;
  uint256 craftingStation;
  uint256 trap;
  bool hasFire;
}

struct ChestData {
  uint256 id;
  uint256 lootTableId;
  uint256 cooldown;
  bool locked;
  bool trapped;
}

struct CombatStats
{
  uint256 attack; //how hard they hit
  uint256 defense; //damage mitigation
  uint256 speed; //who hits first
  uint256 skill; //chance to hit & chance to dodge
}

struct MonsterData { 
  uint256 id; 
  uint256 hitPoints;
  CombatStats combatStats;
  uint256 lootTableId;
}

struct TrapData {
  uint256 id;
  string name;
  uint256 skill; //skill required to disarm or avoid trap
  uint256 damage;
  uint256 cooldown;
}

struct ChestState
{
  uint256 id;
  bool locked;
  bool armed;
  uint256 timestamp;
}

struct MonsterState {
  uint256 id;
  uint256 hitPoints;
  uint256 timestamp; //time when killed and looted
}

struct TrapState {
  uint256 id;
  uint256 timestamp; //triggered or disarmed
}

struct RoomState 
{
  uint256 id; 
  MonsterState[] monsterStates;
  ChestState[] chestStates;
  TrapState trapState;
  //TODO: enumerable list of adventurers
}

//an adventurer can be an arbitrary whitelisted ERC-721
struct Adventurer
{
  address tokenAddress;
  uint256 tokenId;
}

struct AdventurerState
{
  Adventurer adventurer;
  
  address currentDungeon;
  uint256 roomId;
  uint256 seed;
  CombatStats combatStats; //gets set depending on equipped items
  uint256 hitPoints;  //if in a dungeon and it reaches zero they are dead and can only leave dungeon
  uint256 xp; //xpearned for the run - gets added to claimableXp if run is successful
  uint256 claimableXp; // how much xp was earned - can be used by external system to level up the adventurer. this only gets reset after claiming it
  //equipped items
  //inventory a list of items brought into the dungeon; if you die you lose your bag
}

struct MersenneTwisterState
{
  uint[624] MT;
  uint index;
}


