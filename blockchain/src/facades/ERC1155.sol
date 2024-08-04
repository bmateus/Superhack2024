// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { IERC1155 } from "lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import { IERC1155MetadataURI } from "lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import { IERC1155Facet } from "../interfaces/IERC1155Facet.sol";
import { MetaContext } from "../shared/MetaContext.sol";

/**
 * @dev Facade implementation of ERC1155 token.
 * 
 * Our Diamond can deploy multiple such tokens, all backed by the same implementation within the Diamond.
 */
abstract contract ERC1155 is IERC1155, IERC1155MetadataURI, MetaContext {

/**
   * @dev The parent Diamond that implements the business logic.
   */
  IERC1155Facet private _parent;

  /**
   * @dev Constructor.
   *
   * @param parent The parent Diamond that implements the business logic.
   */
  constructor(IERC1155Facet parent) {
    _parent = parent;
  }

  /*
    IERC1155Metadata interface
  */

  function balanceOf(address account, uint256 id) external view override returns (uint256) {
    //_parent.balanceOf(account, id);
  }

  function balanceOfBatch(
    address[] calldata accounts,
    uint256[] calldata ids
  ) external view override returns (uint256[] memory) {

  }

  function setApprovalForAll(address operator, bool approved) external override {

  }

  function isApprovedForAll(
    address account,
    address operator
  ) external view override returns (bool) {

  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external override {

  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external override {

  }

  function uri(uint256 id) external view override returns (string memory) {

  }

}