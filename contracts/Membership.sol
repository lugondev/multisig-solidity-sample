// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

contract Membership is ERC721EnumerableUpgradeable, AccessControlUpgradeable {
    string _prefix;
    bool public transferable;

    event UpdateTransferable(bool transferable);
    event UpdatePrefixURI(string prefix);

    bytes32 public constant CONTROLLER_MANAGER_ROLE =
        keccak256("CONTROLLER_MANAGER_ROLE");

    modifier onlyControllerManager() {
        require(
            hasRole(CONTROLLER_MANAGER_ROLE, _msgSender()),
            "Membership: SENDER_IS_NOT_CONTROLLER_MANAGER"
        );
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _newControllerManager
    ) public initializer {
        __ERC721_init(_name, _symbol);
        transferable = false;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(CONTROLLER_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(CONTROLLER_MANAGER_ROLE, _newControllerManager);
    }

    function _baseURI()
        internal
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return _prefix;
    }

    function updatePrefix(string memory _newPrefix)
        external
        onlyControllerManager
    {
        _prefix = _newPrefix;
        emit UpdatePrefixURI(_newPrefix);
    }

    function updateTransferable(bool _transferable)
        external
        onlyControllerManager
    {
        transferable = _transferable;
        emit UpdateTransferable(_transferable);
    }

    function mint(address _user, uint256 _tokenId)
        external
        onlyControllerManager
    {
        super._mint(_user, _tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (
            hasRole(CONTROLLER_MANAGER_ROLE, _msgSender()) && from != address(0)
        ) {
            require(transferable, "Membership: TRANSFER_IS_FAUSED");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
