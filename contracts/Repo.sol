pragma solidity ^0.4.15;

import "./Ownable.sol";

contract Repo is Ownable {
    struct Version {
        uint16[3] semanticVersion;
        address contractAddress;
        bytes contentURI;
    }

    Version[] versions;
    mapping (bytes32 => uint256) versionIdForSemantic;
    mapping (address => uint256) lastVersionForContract;

    event NewVersion(uint256 versionId, uint16[3] semanticVersion);

    function newVersion(uint16[3] _newSemanticVersion, address _contractAddress, bytes _contentURI) onlyOwner {
        if (versions.length > 0) {
            Version storage lastVersion = versions[versions.length - 1];
            require(isValidBump(lastVersion.semanticVersion, _newSemanticVersion));
            // Only allows smart contract change on major version bumps
            require(lastVersion.contractAddress == _contractAddress || _newSemanticVersion[0] > lastVersion.semanticVersion[0]);
        } else {
            versions.length += 1;
            uint16[3] memory zeroVersion;
            require(isValidBump(zeroVersion, _newSemanticVersion));
        }

        uint versionId = versions.push(Version(_newSemanticVersion, _contractAddress, _contentURI)) - 1;
        versionIdForSemantic[semanticVersionHash(_newSemanticVersion)] = versionId;
        lastVersionForContract[_contractAddress] = versionId;

        NewVersion(versionId, _newSemanticVersion);
    }

    function getLatest() constant returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI) {
        return getVersion(versions.length - 1);
    }

    function getLatestForContractAddress(address _contractAddress) constant returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI) {
        return getVersion(lastVersionForContract[_contractAddress]);
    }

    function getSemanticVersion(uint16[3] _semanticVersion) constant returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI) {
        return getVersion(versionIdForSemantic[semanticVersionHash(_semanticVersion)]);
    }

    function getVersion(uint _versionId) constant returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI) {
        require(_versionId > 0);
        Version storage version = versions[_versionId];
        return (version.semanticVersion, version.contractAddress, version.contentURI);
    }

    function isValidBump(uint16[3] _oldVersion, uint16[3] _newVersion) constant returns (bool) {
        bool hasBumped;
        uint i = 0;
        while (i < 3) {
            if (hasBumped) {
                if (_newVersion[i] != 0) return false;
                } else if (_newVersion[i] != _oldVersion[i]) {
                    if (_newVersion[i] - _oldVersion[i] != 1) return false;
                    hasBumped = true;
                }
                i++;
            }
        return hasBumped;
    }

    function semanticVersionHash(uint16[3] version) constant returns (bytes32) {
        return sha3(version[0], version[1], version[2]);
    }
}