// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";

/**
 * @dev Crafting diamond facet interface.
 */
interface ICraftingFacet {

    // num recipes
    function numRecipes() external view returns (uint256);

    // get recipe
    function getRecipe(uint256 index) external view returns (Recipe memory);

    // craft
    function craft(uint256 index) external;

    //admin:

    function addRecipe(Recipe memory recipe) external;

}