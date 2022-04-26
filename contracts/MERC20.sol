// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IMERC20.sol";

abstract contract MERC20 is OwnableUpgradeable, IMERC20, PausableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event MapAddress(address indexed from, address target);
    event UnMapAddress(address indexed from, address target);

    mapping(address => address) private mapAddresses;
    mapping(address => EnumerableSet.AddressSet) targetMapAddress;

    mapping(address => address) _requestTargets;
    mapping(address => EnumerableSet.AddressSet) pendingRequestTarget;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __MERC20_init(string memory name_, string memory symbol_)
        internal
        initializer
    {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[mappedAddress(account)];
    }

    /**
     * @dev address after mapping
     */
    function mappedAddress(address account)
        public
        view
        override
        returns (address)
    {
        return
            mapAddresses[account] != address(0)
                ? mapAddresses[account]
                : account;
    }

    /**
     * @dev map address's balance to new target address
     */
    function _mapAddress(address account, address target)
        internal
        returns (bool)
    {
        require(mapAddresses[account] == address(0), "already mapped");
        require(mapAddresses[target] != account, "loop mapping denied");
        mapAddresses[account] = target;
        targetMapAddress[target].add(account);

        if (isTargetMapAddress(account)) {
            for (
                uint256 index = 0;
                index < targetMapAddress[account].length() - 1;
                index++
            ) {
                address childAddress = targetMapAddress[target].at(index);
                mapAddresses[childAddress] = target;
                emit UnMapAddress(childAddress, account);
                emit MapAddress(childAddress, target);
            }
        }

        emit MapAddress(account, target);
        return true;
    }

    /**
     * @dev unmap address's balance
     */
    function _unmapAddress(address account) internal returns (bool) {
        require(mapAddresses[account] != address(0), "not mapped");
        address target = mapAddresses[account];
        require(targetMapAddress[target].contains(account));

        mapAddresses[account] = address(0);
        targetMapAddress[target].remove(account);

        emit UnMapAddress(account, target);
        return true;
    }

    /**
     * @dev count total addresses is targeting to account
     */
    function countTargetMapAddress(address account)
        public
        view
        returns (uint256)
    {
        return targetMapAddress[account].length();
    }

    /**
     * @dev get addresses is targeting to account by index
     */
    function getTargetMapAddressByIndex(address account, uint256 index)
        public
        view
        returns (address)
    {
        return targetMapAddress[account].at(index);
    }

    /**
     * @dev status targeting address
     */
    function isTargetMapAddress(address account) public view returns (bool) {
        return countTargetMapAddress(account) > 0;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address account = mappedAddress(_msgSender());
        recipient = mappedAddress(recipient);
        _transfer(account, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        spender = mappedAddress(spender);
        owner = mappedAddress(owner);
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address account = mappedAddress(_msgSender());
        spender = mappedAddress(spender);
        _approve(account, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-force-approve}.
     */
    function forceApprove(
        address account,
        address spender,
        uint256 amount
    ) internal returns (bool) {
        _approve(account, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-force-transfer}.
     */
    function forceTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        sender = mappedAddress(sender);
        recipient = mappedAddress(recipient);
        _transfer(sender, recipient, amount);
        address account = mappedAddress(_msgSender());

        uint256 currentAllowance = _allowances[sender][account];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, account, currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        spender = mappedAddress(spender);
        address account = mappedAddress(_msgSender());
        _approve(account, spender, _allowances[account][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        spender = mappedAddress(spender);
        address account = mappedAddress(_msgSender());
        uint256 currentAllowance = _allowances[account][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(account, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        require(!paused(), "ERC20Pausable: token transfer while paused");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        account = mappedAddress(account);

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        account = mappedAddress(account);

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function acceptMapAddress(address _requester) public override {
        require(
            _requestTargets[_requester] == _msgSender(),
            "dont have permission: denied"
        );
        forceApprove(_requester, address(this), ~uint256(0));
        uint256 balance = balanceOf(_requester);
        if (balance > 0) transferFrom(_requester, _msgSender(), balance);

        _mapAddress(_requester, _msgSender());
        pendingRequestTarget[_msgSender()].remove(_requester);
    }

    function requestTarget(address _target) public override returns (bool) {
        if (_target == address(0)) {
            require(
                _requestTargets[_msgSender()] != address(0),
                "cannot cancel request"
            );
            _requestTargets[_msgSender()] = address(0);
            return true;
        }
        require(
            _requestTargets[_msgSender()] == address(0),
            "wait to target accept"
        );
        _requestTargets[_msgSender()] = _target;
        pendingRequestTarget[_target].add(_msgSender());

        return true;
    }

    function unmapAddress() public override {
        _unmapAddress(_msgSender());
    }

    function countPendingRequestTarget(address _account)
        public
        view
        override
        returns (uint256)
    {
        return pendingRequestTarget[_account].length();
    }

    function getPendingRequestTargetByIndex(address _account, uint256 _index)
        public
        view
        override
        returns (address)
    {
        return pendingRequestTarget[_account].at(_index);
    }

    function requestTargets(address _account)
        public
        view
        override
        returns (address)
    {
        return _requestTargets[_account];
    }
}
