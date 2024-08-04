// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { ICraftingFacet } from "../interfaces/ICraftingFacet.sol";
import { AccessControl } from "../shared/AccessControl.sol";

import "../shared/Structs.sol";

import { console2 } from "forge-std/console2.sol";

contract CraftingFacet is ICraftingFacet, AccessControl {

  function numRecipes() external view override returns (uint256) {}

  function getRecipe(uint256 index) external view override returns (Recipe memory) {}

  function craft(uint256 index) external override {}

  function addRecipe(Recipe memory recipe) external override {}

}