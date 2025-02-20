// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IPublicationHook {
    /// @notice Hook called before a publication
    /// @param publisher The address of the publisher
    /// @param input Arbitrary input to the hook
    /// @return output Arbitrary output from the hook. Commonly used to return the metadata for the publication.
    function beforePublish(address publisher, bytes memory input) external payable returns (bytes memory output);

    /// @notice Hook called after a publication
    /// @param publisher The address of the publisher
    /// @param input Arbitrary input to the hook
    /// @return output Arbitrary output from the hook.
    function afterPublish(address publisher, bytes memory input) external payable returns (bytes memory output);
}
