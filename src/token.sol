pragma solidity ^0.4.2;

contract owned {
	address public owner;

	function owned() {
		owner = msg.sender;
	}

	function changeOwner(address newOwner) onlyOwner {
		owner = newOwner;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
}


contract tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);}


contract CSToken is owned {
	struct Dividend {
		uint256 time;
		uint256 tenThousandth;
		bool isComplete;
		uint256 countComplete;
	}

	/* Public variables of the token */
	string public standard = 'Token 0.1';

	string public name = 'Kick Coin';

	string public symbol = 'KC';

	uint8 public decimals = 8;

	uint256 _totalSupply = 0;

	/* This creates an array with all balances */
	mapping (address => uint256) balances;

	mapping (address => mapping (uint256 => uint256)) public agingBalanceOf;

	uint[] agingTimes;

	Dividend[] dividends;

	mapping (address => mapping (address => uint256)) allowed;
	/* This generates a public event on the blockchain that will notify clients */
	event Transfer(address indexed from, address indexed to, uint256 value);

	event AgingTransfer(address indexed from, address indexed to, uint256 value, uint256 agingTime);

	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	address[] public addressByIndex;

	mapping (address => bool) addressAddedToIndex;

	mapping (address => uint) agingTimesForPools;

	/* Initializes contract with initial supply tokens to the creator of the contract */
	function CSToken() {
		owner = msg.sender;
		dividends.push(Dividend(1509454800, 1000, false, 0));
		dividends.push(Dividend(1512046800, 900, false, 0));
		dividends.push(Dividend(1514725200, 800, false, 0));
		dividends.push(Dividend(1517403600, 725, false, 0));
		dividends.push(Dividend(1519822800, 650, false, 0));
		dividends.push(Dividend(1522501200, 600, false, 0));
		dividends.push(Dividend(1525093200, 550, false, 0));
		dividends.push(Dividend(1527771600, 500, false, 0));
		dividends.push(Dividend(1530363600, 450, false, 0));
		dividends.push(Dividend(1533042000, 425, false, 0));
		dividends.push(Dividend(1535720400, 400, false, 0));
		dividends.push(Dividend(1538312400, 375, false, 0));
		dividends.push(Dividend(1540990800, 350, false, 0));
		dividends.push(Dividend(1543582800, 325, false, 0));
		dividends.push(Dividend(1546261200, 300, false, 0));
		dividends.push(Dividend(1548939600, 275, false, 0));
		dividends.push(Dividend(1551358800, 250, false, 0));
		dividends.push(Dividend(1554037200, 225, false, 0));
		dividends.push(Dividend(1556629200, 200, false, 0));
		dividends.push(Dividend(1559307600, 175, false, 0));
		dividends.push(Dividend(1561899600, 150, false, 0));
		dividends.push(Dividend(1564578000, 125, false, 0));
		dividends.push(Dividend(1567256400, 100, false, 0));
		dividends.push(Dividend(1569848400, 75, false, 0));
	}

	function totalSupply() constant returns (uint256 totalSupply) {
		totalSupply = _totalSupply;
	}

	function balanceOf(address _owner) constant returns (uint256 balance) {
		return balances[_owner];
	}

	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	function addAgingTime(uint256 time) onlyOwner {
		agingTimes.push(time);
	}

	function calculateDividends(uint256 which, uint256 limit) {
		require(now >= dividends[which].time && !dividends[which].isComplete);

		if(limit == 0)
			limit = addressByIndex.length;

		limit = dividends[which].countComplete + limit;
		if(limit > addressByIndex.length)
			limit = addressByIndex.length;

		for (uint256 i = dividends[which].countComplete; i < limit; i++) {
			uint256 add = balances[addressByIndex[i]] * dividends[which].tenThousandth / 10000;
			balances[addressByIndex[i]] += add;
			Transfer(0, owner, add);
			Transfer(owner, addressByIndex[i], add);
			if (agingBalanceOf[addressByIndex[i]][0] > 0) {
				agingBalanceOf[addressByIndex[i]][0] += agingBalanceOf[addressByIndex[i]][0] * dividends[which].tenThousandth / 10000;
				for (uint256 k = 0; k < agingTimes.length; k++) {
					agingBalanceOf[addressByIndex[i]][agingTimes[k]] += agingBalanceOf[addressByIndex[i]][agingTimes[k]] * dividends[which].tenThousandth / 10000;
				}
			}
		}
		if(limit == addressByIndex.length)
			dividends[which].isComplete = true;
		else
			dividends[which].countComplete = limit;
	}

	/* Send coins */
	function transfer(address _to, uint256 _value) returns (bool success) {
		checkMyAging(msg.sender);
		require(accountBalance(msg.sender) >= _value);

		require(balances[_to] + _value > balances[_to]);
		// Check for overflows

		balances[msg.sender] -= _value;
		// Subtract from the sender

		if (agingTimesForPools[msg.sender] > 0 && agingTimesForPools[msg.sender] > now) {
			addToAging(msg.sender, _to, agingTimesForPools[msg.sender], _value);
		}

		balances[_to] += _value;
		addIndex(_to);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	function mintToken(address target, uint256 mintedAmount, uint256 agingTime) onlyOwner {
		if (agingTime > now) {
			addToAging(owner, target, agingTime, mintedAmount);
		}

		balances[target] += mintedAmount;

		_totalSupply += mintedAmount;
		addIndex(target);
		Transfer(0, owner, mintedAmount);
		Transfer(owner, target, mintedAmount);
	}

	function addIndex(address _address) internal {
		if (!addressAddedToIndex[_address]) {
			addressAddedToIndex[_address] = true;
			addressByIndex.push(_address);
		}
	}

	function addToAging(address from, address target, uint256 agingTime, uint256 amount) internal {
		agingBalanceOf[target][0] += amount;
		agingBalanceOf[target][agingTime] += amount;
		AgingTransfer(from, target, amount, agingTime);
	}

	/* Allow another contract to spend some tokens in your behalf */
	function approve(address _spender, uint256 _value) returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	/* Approve and then communicate the approved contract in a single tx */
	function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}

	/* A contract attempts to get the coins */
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
		checkMyAging(_from);
		require(accountBalance(_from) >= _value);
		// Check if the sender has enough
		assert(balances[_to] + _value > balances[_to]);
		// Check for overflows
		require(_value <= allowed[_from][msg.sender]);
		// Check allowed
		balances[_from] -= _value;
		// Subtract from the sender
		balances[_to] += _value;
		// Add the same to the recipient
		allowed[_from][msg.sender] -= _value;

		if (agingTimesForPools[_from] > 0 && agingTimesForPools[_from] > now) {
			addToAging(_from, _to, agingTimesForPools[_from], _value);
		}

		addIndex(_to);
		Transfer(_from, _to, _value);
		return true;
	}

	/* This unnamed function is called whenever someone tries to send ether to it */
	function() {
		revert();
		// Prevents accidental sending of ether
	}

	function checkMyAging(address sender) internal {
		if(agingBalanceOf[sender][0] == 0) return;

		for (uint256 k = 0; k < agingTimes.length; k++) {
			if(agingTimes[k] < now) {
				agingBalanceOf[sender][0] -= agingBalanceOf[sender][agingTimes[k]];
				agingBalanceOf[sender][agingTimes[k]] = 0;
			}
		}
	}

	function addAgingTimesForPool(address poolAddress, uint256 agingTime) onlyOwner {
		agingTimesForPools[poolAddress] = agingTime;
	}

	function countAddresses() constant returns (uint256 length) {
		return addressByIndex.length;
	}

	function accountBalance(address _address) constant returns (uint256 balance) {
		return balances[_address] - agingBalanceOf[_address][0];
	}
}