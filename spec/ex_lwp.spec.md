# EARS
## Syntax: While <optional pre-condition>, when <optional trigger>, the <system name> shall <system response>
## Examples
Ubiquitous requirements
Ubiquitous requirements are always active (so there is no EARS keyword)

The <system name> shall <system response>

Example: The mobile phone shall have a mass of less than XX grams.

State driven requirements
State driven requirements are active as long as the specified state remains true and are denoted by the keyword While.

While <precondition(s)>, the <system name> shall <system response>

Example: While there is no card in the ATM, the ATM shall display “insert card to begin”.

Event driven requirements
Event driven requirements specify how a system must respond when a triggering event occurs and are denoted by the keyword When.

When <trigger>, the <system name> shall <system response>

Example: When “mute” is selected, the laptop shall suppress all audio output.

Optional feature requirements
Optional feature requirements apply in products or systems that include the specified feature and are denoted by the keyword Where.

Where <feature is included>, the <system name> shall <system response>

Example: Where the car has a sunroof, the car shall have a sunroof control panel on the driver door.

Unwanted behaviour requirements
Unwanted behaviour requirements are used to specify the required system response to undesired situations and are denoted by the keywords If and Then.

If <trigger>, then the <system name> shall <system response>

Example: If an invalid credit card number is entered, then the website shall display “please re-enter credit card details”.

Complex requirements
The simple building blocks of the EARS patterns described above can be combined to specify requirements for richer system behaviour. Requirements that include more than one EARS keyword are called Complex requirements.

While <precondition(s)>, When <trigger>, the <system name> shall <system response>

# Requirement IDs

Every requirement is a list item starting with a unique ID, like
`- [ARCH-4] The ExLWP shall ...`. Tests and reviews refer
to requirements by ID, so:

- To add a requirement, give it the next free ID in its section.
- To reword a requirement without changing its meaning, keep its ID.
- To change what a requirement means, give it a new ID. Its old tests
  and reviews then no longer count, until they are updated.
- To remove a requirement, delete it. Never reuse its ID.

Run `mix spec` to see which requirements are implemented, in
[STATUS.md](STATUS.md).

# Scope

"The protocol" below means the LEGO Wireless Protocol 3.0.00 as documented
at https://lego.github.io/lego-ble-wireless-protocol-docs/: the advertising
data (section 2) and the messages of the LEGO Hub Characteristic (section 3).

Not in scope, for now:

- The Boot Loader service (section 5). Its documentation contradicts itself
  on message sizes and on whether messages carry the common header, and
  getting it wrong can leave a hub unbootable.
- The Buffering State Machine (section 4) and the Transmission Flow Control
  proposal (section 3.4). Tracking them needs state, and the ExLWP is
  stateless; the Port Output Command Feedback messages they rely on are in
  scope.

# Spec

## Architecture
- [ARCH-1] The hex package name for this LEGO Wireless Protocol Message Handler shall be ex_lwp
- [ARCH-2] The top level namespace for this project shall be ExLWP

- [ARCH-3] The ExLWP shall be implemented in Elixir
- [ARCH-4] The ExLWP shall be completely stateless
- [ARCH-5] The ExLWP shall implement the message encoding/decoding described on https://lego.github.io/lego-ble-wireless-protocol-docs/
- [ARCH-6] The ExLWP shall allow creation of the messages described on https://lego.github.io/lego-ble-wireless-protocol-docs/ via easy to use functions
- [ARCH-7] The ExLWP shall allow creation of the messages described on https://lego.github.io/lego-ble-wireless-protocol-docs/ via bitstrings
- [ARCH-8] The ExLWP shall allow encoding and decoding of messages
- [ARCH-9] The ExLWP shall have no runtime dependencies

## Framing
- [FRAME-1] When a message is encoded, the ExLWP shall prefix it with the common message header: length, hub ID and message type
- [FRAME-2] When a message, including its header, is 127 bytes or shorter, the ExLWP shall encode its length in one byte
- [FRAME-3] When a message, including its header, is longer than 127 bytes, the ExLWP shall encode its length in two bytes, as described in Message Length Encoding
- [FRAME-4] Where no hub ID is given, the ExLWP shall set the hub ID to 0x00
- [FRAME-5] When given bytes holding partial or multiple messages, the ExLWP shall decode every complete message and hand back the remaining bytes
- [FRAME-6] If a message's length field does not match its size, then the ExLWP shall return an error

## Encoding
- [ENC-1] If a message field does not fit its documented size or range, then the ExLWP shall raise an ArgumentError instead of sending truncated bytes
- [ENC-2] When a message has a documented safety string or checksum, the ExLWP shall add it
- [ENC-3] When a field is an enumeration or a bit-field, the ExLWP shall accept its documented names as atoms

## Decoding
- [DEC-1] If bytes hold an unknown message type, then the ExLWP shall return an error naming the message type
- [DEC-2] If a message's payload does not match its documented layout, then the ExLWP shall return an error naming the message
- [DEC-3] When an enumeration or bit-field holds a value without a documented name, the ExLWP shall pass the value through as an integer
- [DEC-4] When the ExLWP decodes bytes it has encoded, the ExLWP shall return the original message
- [DEC-5] If decoding fails, then the ExLWP shall return an error tuple instead of raising

## Messages
- [MSG-1] The ExLWP shall encode and decode Hub Properties messages, with a typed value for every documented property
- [MSG-2] The ExLWP shall encode and decode Hub Actions messages
- [MSG-3] The ExLWP shall encode and decode Hub Alerts messages
- [MSG-4] The ExLWP shall encode and decode Hub Attached I/O messages for detached, attached and attached virtual I/O
- [MSG-5] The ExLWP shall encode and decode Generic Error messages
- [MSG-6] The ExLWP shall encode and decode every documented H/W NetWork command
- [MSG-7] The ExLWP shall encode and decode the F/W update messages: Go Into Boot Mode, Lock Memory, Lock Status Request and Lock Status
- [MSG-8] The ExLWP shall encode and decode Port Information Request, Port Mode Information Request, Port Information and Port Mode Information messages, with a typed value for every documented information type
- [MSG-9] The ExLWP shall encode and decode Port Input Format Setup and Port Input Format messages, in single and combined mode
- [MSG-10] The ExLWP shall encode and decode Port Value messages, in single and combined mode
- [MSG-11] Since the size of a port value depends on the port's mode, the ExLWP shall return port values as raw bytes and decode them on request, given the mode's Value Format
- [MSG-12] The ExLWP shall encode and decode Virtual Port Setup messages
- [MSG-13] The ExLWP shall encode and decode Port Output Commands, with every documented sub command
- [MSG-14] When a documented output sub command is encoded through WriteDirectModeData or WriteDirect, the ExLWP shall provide a function that builds it
- [MSG-15] The ExLWP shall encode and decode Port Output Command Feedback messages for one or more ports
- [MSG-16] The ExLWP shall decode version numbers, in Version Number Encoding and LWP Version Number Encoding, into their major, minor, bug fixing and build numbers

## Bluetooth
- [BLE-1] The ExLWP shall provide the UUIDs of the LEGO Hub Service and the LEGO Hub Characteristic
- [BLE-2] The ExLWP shall decode the Manufacturer Data a hub sends when advertising

## Documentation
- [DOC-1] The ExLWP shall have concise and easy to read documentation
- [DOC-2] The ExLWP shall make it clear that there is no affiliation with The LEGO Group

## Testing
- [TEST-1] The ExLWP shall have easy to read tests in a BDD style
