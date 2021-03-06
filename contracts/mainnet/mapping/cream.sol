//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IndexInterface {
    function master() external view returns (address);
}

interface ConnectorsInterface {
    function chief(address) external view returns (bool);
}

interface CTokenInterface {
    function isCToken() external view returns (bool);
    function underlying() external view returns (address);
}

interface MappingControllerInterface {
    function hasRole(address,address) external view returns (bool);
}

abstract contract Helpers {

    struct TokenMap {
        address ctoken;
        address token;
    }

    event LogCTokenAdded(string indexed name, address indexed token, address indexed ctoken);
    event LogCTokenUpdated(string indexed name, address indexed token, address indexed ctoken);

    // TODO: thrilok, verify this address
    ConnectorsInterface public constant connectors = ConnectorsInterface(0xFE2390DAD597594439f218190fC2De40f9Cf1179);
    

    // InstaIndex Address.
    IndexInterface public constant instaIndex = IndexInterface(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    // TODO: add address for MappingController
    MappingControllerInterface public constant mappingController = MappingControllerInterface(address(0));

    address public constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping (string => TokenMap) public cTokenMapping;

    modifier hasRoleOrIsChief {
        require(
            msg.sender == instaIndex.master() ||
                connectors.chief(msg.sender) ||
                mappingController.hasRole(address(this), msg.sender),
            "not-an-chief"
        );
        _;
    }

    function _addCtokenMapping(
        string[] memory _names,
        address[] memory _tokens,
        address[] memory _ctokens
    ) internal {
        require(_names.length == _tokens.length, "addCtokenMapping: not same length");
        require(_names.length == _ctokens.length, "addCtokenMapping: not same length");

        for (uint i = 0; i < _ctokens.length; i++) {
            TokenMap memory _data = cTokenMapping[_names[i]];

            require(_data.ctoken == address(0), "addCtokenMapping: mapping added already");
            require(_data.token == address(0), "addCtokenMapping: mapping added already");

            require(_tokens[i] != address(0), "addCtokenMapping: _tokens address not vaild");
            require(_ctokens[i] != address(0), "addCtokenMapping: _ctokens address not vaild");

            CTokenInterface _ctokenContract = CTokenInterface(_ctokens[i]);

            require(_ctokenContract.isCToken(), "addCtokenMapping: not a cToken");
            if (_tokens[i] != ethAddr) {
                require(_ctokenContract.underlying() == _tokens[i], "addCtokenMapping: mapping mismatch");
            }

            cTokenMapping[_names[i]] = TokenMap(
                _ctokens[i],
                _tokens[i]
            );
            emit LogCTokenAdded(_names[i], _tokens[i], _ctokens[i]);
        }
    }

    function updateCtokenMapping(
        string[] calldata _names,
        address[] memory _tokens,
        address[] calldata _ctokens
    ) external {
        require(msg.sender == instaIndex.master(), "not-master");

        require(_names.length == _tokens.length, "updateCtokenMapping: not same length");
        require(_names.length == _ctokens.length, "updateCtokenMapping: not same length");

        for (uint i = 0; i < _ctokens.length; i++) {
            TokenMap memory _data = cTokenMapping[_names[i]];

            require(_data.ctoken != address(0), "updateCtokenMapping: mapping does not exist");
            require(_data.token != address(0), "updateCtokenMapping: mapping does not exist");

            require(_tokens[i] != address(0), "updateCtokenMapping: _tokens address not vaild");
            require(_ctokens[i] != address(0), "updateCtokenMapping: _ctokens address not vaild");

            CTokenInterface _ctokenContract = CTokenInterface(_ctokens[i]);

            require(_ctokenContract.isCToken(), "updateCtokenMapping: not a cToken");
            if (_tokens[i] != ethAddr) {
                require(_ctokenContract.underlying() == _tokens[i], "addCtokenMapping: mapping mismatch");
            }

            cTokenMapping[_names[i]] = TokenMap(
                _ctokens[i],
                _tokens[i]
            );
            emit LogCTokenUpdated(_names[i], _tokens[i], _ctokens[i]);
        }
    }

    function addCtokenMapping(
        string[] memory _names,
        address[] memory _tokens,
        address[] memory _ctokens
    ) external hasRoleOrIsChief {
        _addCtokenMapping(_names, _tokens, _ctokens);
    }

    function getMapping(string memory _tokenId) external view returns (address, address) {
        TokenMap memory _data = cTokenMapping[_tokenId];
        return (_data.token, _data.ctoken);
    }

}

contract InstaCreamMapping is Helpers {
    string constant public name = "Cream-Mapping-v1.1";

    constructor(
        address _connectors,
        string[] memory _ctokenNames,
        address[] memory _tokens,
        address[] memory _ctokens
    )  {
        _addCtokenMapping(_ctokenNames, _tokens, _ctokens);
    }
}
