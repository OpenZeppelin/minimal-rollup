// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "./IDataFeed.sol";

interface IPublicationHook {
    /// @notice Hook called before a publication
    /// @param publisher The address of the publisher
    /// @param input Arbitrary input to the hook
    /// @return auxData Auxiliary data that should be contained within the publication
    /// @dev Auxiliary data is typically publication metadata and any other relevant L1 state.
    function beforePublish(address publisher, bytes memory input) external payable returns (bytes memory auxData);

    /// @notice Hook called after a publication
    /// @param publisher The address of the publisher
    /// @param publication The publication that was just included
    /// @param input Arbitrary input to the hook
    function afterPublish(address publisher, IDataFeed.Publication memory publication, bytes memory input)
        external
        payable;
}
