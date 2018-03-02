pragma solidity ^0.4.18;
import "./ERC20Interface.sol";

contract DullChannel {

  //============================================================================
  // GLOBAL VARIABLES
  //============================================================================

  struct Channel {
    address house;
    address player;
    address token;
    uint depositHouse;       // Deposit of agent A
    uint depositPlayer;       // Deposit of agent B
    bool openHouse;          // True if A->B is open
    bool openPlayer;          // True if B->A is open
  }

  mapping (bytes32 => Channel) channels;
  mapping (address => mapping(address => bytes32)) active_ids;


  //============================================================================
  // STATE TRANSITION FUNCTIONS
  //============================================================================

	/**
	 * Open a channel with a recipient. A non-zero message value must be included.
   *
	 * address token    Address of token contract
	 * address to       Address of recipient
   * uint amount      Number of token quanta to send
	 */
	function openChannel(address token, address to, uint amount) public {
    // Sanity checks
    require (amount > 0);
    require (to != msg.sender);
    require (active_ids[msg.sender][to] == bytes32(0));

    // Create a channel
    bytes32 id = keccak256(msg.sender, to, now);

    // Initialize the channel
    Channel memory _channel;
    _channel.house = msg.sender;
    _channel.player = to;
    _channel.token = token;
    _channel.depositHouse = amount;     // Note that the actor opening the channel is actorA
    _channel.openHouse = true;
    _channel.openPlayer = true;

    // Make the deposit
    ERC20Interface t = ERC20Interface(token);
    if (!t.transferFrom(msg.sender, address(this), amount)) { 
      revert(); 
    }

    channels[id] = _channel;

    // Add it to the lookup table
    active_ids[msg.sender][to] = id;
	}


  /**
   * Add to either depositHouse or depositPlayer
   *
   * bytes32 id     Channel id
   * uint amount    Amount of tokens to be deposited
   */
  function addDeposit(bytes32 id, uint amount) public {
    // Make sure the channel exists
    require (channels[id].token != address(0));

    Channel memory _channel;
    _channel = channels[id];
    ERC20Interface t = ERC20Interface(_channel.token);

    // As long as the channel exists, either party can add to the deposit
    if (msg.sender == _channel.house && _channel.openHouse == true) {
      if (!t.transferFrom(msg.sender, address(this), amount)) { 
        revert();
      }
      _channel.depositHouse += amount;
    } else if (msg.sender == _channel.player && _channel.openPlayer == true) {
      if (!t.transferFrom(msg.sender, address(this), amount)) {
        revert(); 
      }
      _channel.depositPlayer += amount;
    } else {
      revert();
    }

  }


	/**
	 * Close a channel at any time. May only be called by sender or recipient.
   * The "value" is sent to the recipient and the remainder is refunded to the sender.
	 *
	 * bytes32 id     Identifier of "channels" mapping
	 * bytes32 h      [ id, msg_hash, r, s ]
	 * uint8 v        Component of signature of "h" coming from sender
	 * bytes32 r      Component of signature of "h" coming from sender
	 * bytes32 s      Component of signature of "h" coming from sender
	 * uint value     Amount of wei sent
	 */
	function closeChannel(bytes32[4] h, uint8 v, uint256 value) public {
    // h[0]    Channel id
    // h[1]    Hash of (id, value)
    // h[2]    r of signature
    // h[3]    s of signature

    // Make sure the channel is open
    require (channels[h[0]].token != address(0));
    Channel memory _channel;
    _channel = channels[h[0]];

    require (msg.sender == _channel.house || msg.sender == _channel.player);

    // Get the message signer and construct a proof
    address signer = ecrecover(h[1], v, h[2], h[3]);
    bytes32 proof = keccak256(h[0], value);
    // Make sure the hash provided is of the channel id and the amount sent
    // Ensure the proof matches, send the value, send the remainder, and delete the channel
    require (proof == h[1]);

    // Pay recipient and refund sender the remainder
    ERC20Interface t = ERC20Interface(_channel.token);

    if (msg.sender == _channel.house && signer == _channel.player) {
      // Close out the B->A side of the channel
      if (value > _channel.depositPlayer) { 
        revert(); 
      }

      if (!t.transfer(_channel.house, value)) { 
        revert(); 
      } else if (!t.transfer(_channel.player, _channel.depositPlayer-value)) { 
        revert(); 
      }

      // Close this side of the channel
      _channel.openPlayer = false;
      // Close the other side if no deposit was ever made
      if (_channel.depositHouse == 0) {
        _channel.openHouse = false;
      }
      // Update the state
      channels[h[0]] = _channel;
    } else if (msg.sender == _channel.player && signer == _channel.house) {
      // Close out the A->B side of the channel
      if (value > _channel.depositHouse) { 
        revert(); 
      }

      if (!t.transfer(_channel.player, value)) { 
        revert(); 
      } else if (!t.transfer(_channel.house, _channel.depositHouse-value)) { 
        revert(); 
      }

      // Close this side of the channel
      _channel.openHouse = false;
      // Update the state
      channels[h[0]] = _channel;
    }

    // If both sides of the channel are closed, delete the channel
    if (_channel.openHouse == false && _channel.openPlayer == false) {
      // Close the channel
      delete channels[h[0]];
      delete active_ids[_channel.house][_channel.player];
    }

	}

  //============================================================================
  // CONSTANT FUNCTIONS
  //============================================================================

  /**
   * Verify that a message sent will allow the channel to close.
   * Parameters are the same as for closeChannel
   */
  function verifyMsg(bytes32[4] h, uint8 v, uint256 value) public view returns (bool) {
    // h[0]    Channel id
    // h[1]    Hash of (id, value)
    // h[2]    r of signature
    // h[3]    s of signature

    // Make sure the channel is open
    require (channels[h[0]].token != address(0));
    Channel memory _channel;
    _channel = channels[h[0]];

    if (msg.sender != _channel.house && msg.sender != _channel.player) { 
      return false;
    }

    // Get the message signer and construct a proof
    address signer = ecrecover(h[1], v, h[2], h[3]);
    bytes32 proof = keccak256(h[0], value);
    // Make sure the hash provided is of the channel id and the amount sent
    // Ensure the proof matches, send the value, send the remainder, and delete the channel
    if (proof != h[1]) { 
      return false; 
    }

    // Pay recipient and refund sender the remainder
    ERC20Interface t = ERC20Interface(_channel.token);

    if (msg.sender == _channel.house && signer == _channel.player) {
      if (value > _channel.depositPlayer) { 
        return false; 
      }

      // Close out the B->A side of the channel
      if (!t.transfer(_channel.house, value)) { 
        return false; 
      } else if (!t.transfer(_channel.player, _channel.depositPlayer-value)) { 
        return false; 
      }

      // Close this side of the channel
      _channel.openPlayer = false;
      // Close the other side if no deposit was ever made
      if (_channel.depositHouse == 0) {
        _channel.openHouse = false;
      }
    } else if (msg.sender == _channel.player && signer == _channel.house) {
      if (value > _channel.depositHouse) { 
        return false; 
      }

      // Close out the A->B side of the channel
      if (!t.transfer(_channel.player, value)) { 
        return false; 
      } else if (!t.transfer(_channel.house, _channel.depositHouse-value)) { 
        return false; 
      }
    }

    return true;
  }

  // GETTERS

  function getChannelId(address from, address to) public view returns (bytes32) {
    return active_ids[from][to];
  }

  function getDepositA(bytes32 id) public view returns (uint) {
    return channels[id].depositHouse;
  }

  function getDepositB(bytes32 id) public view returns (uint) {
    return channels[id].depositPlayer;
  }

  function getAgentA(bytes32 id) public view returns (address) {
    return channels[id].house;
  }

  function getAgentB(bytes32 id) public view returns (address) {
    return channels[id].player;
  }

  function getToken(bytes32 id) public view returns (address) {
    return channels[id].token;
  }


}