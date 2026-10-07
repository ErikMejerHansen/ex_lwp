# ExLWP

Stateless encoder and decoder for the LEGO® Wireless Protocol 3.0, used by
the Powered Up hubs (Boost Move Hub, City Hub, Technic Hub, remote control
and others), written in Elixir and based on the
[official protocol documentation](https://lego.github.io/lego-ble-wireless-protocol-docs/).

> [!IMPORTANT]
> ExLWP is an independent project. It is **not affiliated with**, sponsored,
> authorized or endorsed by The LEGO Group. LEGO® and Powered Up are
> trademarks of The LEGO Group.

ExLWP turns messages into bytes and bytes into messages. It holds no state
and starts no processes: you bring the BLE connection.

## Installation

```elixir
def deps do
  [{:ex_lwp, "~> 0.1.0"}]
end
```

## Usage

### Connecting

Hubs advertise the LEGO Hub Service. All messages go through its one
characteristic: write to it, and subscribe to its notifications.

```elixir
ExLWP.service_uuid()         #=> "00001623-1212-efde-1623-785feabcd123"
ExLWP.characteristic_uuid()  #=> "00001624-1212-efde-1623-785feabcd123"
```

`ExLWP.Advertisement.decode/1` reads the hub type, button state and more
from the manufacturer data in its advertisement.

### Sending messages

Build a message and encode it, header included:

```elixir
ExLWP.Messages.request_hub_property(:battery_voltage) |> ExLWP.encode()
#=> <<5, 0, 1, 6, 5>>

# Run the motor on port 0 for one turn at 50% speed
ExLWP.Messages.start_speed_for_degrees(0, 360, 50) |> ExLWP.encode()

# Messages can also be written as raw bitstrings, starting with the message type:
ExLWP.encode(<<0x02, 0x01>>)   # switch the hub off
```

### Receiving messages

```elixir
case ExLWP.decode(notification) do
  {:ok, %ExLWP.Message.HubAttachedIO{port: port, event: :attached, io_type: type}} ->
    IO.puts("#{type} attached to port #{port}")

  {:ok, %ExLWP.Message.HubProperty{property: :battery_voltage, value: percent}} ->
    IO.puts("Battery at #{percent}%")

  {:ok, other} ->
    IO.inspect(other)

  {:error, reason} ->
    IO.inspect(reason, label: "could not decode")
end
```

A notification normally holds one message. If yours can hold partial or
several messages, use `ExLWP.decode_stream/1` and keep the rest for the next
notification:

```elixir
{results, rest} = ExLWP.decode_stream(rest <> notification)
```

### Reading sensors

Port values come as raw bytes, as their format depends on the port's mode.
Ask the hub for the mode's value format once, then decode values with it:

```elixir
# Put the motor on port 0 in mode 2 (position), and ask for its value format
ExLWP.Messages.port_input_format_setup(0, 2, 1)
ExLWP.Messages.port_mode_information_request(0, 2, :value_format)

# The hub replies with the format...
{:ok, %ExLWP.Message.PortModeInformation{value: format}} = ExLWP.decode(reply)

# ...and then sends values in it
{:ok, %ExLWP.Message.PortValueSingle{port: 0, value: bytes}} = ExLWP.decode(update)
{:ok, [position]} = ExLWP.ValueFormat.decode(format, bytes)
```

## Modules

| Module                | Purpose                                              |
| --------------------- | ---------------------------------------------------- |
| `ExLWP`               | Encode/decode messages, header included              |
| `ExLWP.Messages`      | Functions that build the messages a client sends     |
| `ExLWP.Message`       | Message structs to/from raw bytes                    |
| `ExLWP.Output`        | Sub commands of port output commands                 |
| `ExLWP.Header`        | The common header: length, hub ID, stream splitting  |
| `ExLWP.ValueFormat`   | Decodes port values                                  |
| `ExLWP.Version`       | Firmware, hardware and protocol versions             |
| `ExLWP.Advertisement` | Manufacturer data in a hub's advertisement           |
| `ExLWP.Enums`         | Protocol enumerations and bit-fields as atoms        |

The Boot Loader service (section 5 of the documentation) is not supported
yet, see [the spec](https://github.com/ErikMejerHansen/ex_lwp/blob/main/spec/ex_lwp.spec.md).

## Development

```sh
mix test      # BDD style tests and doctests
mix spec      # tests, plus writes spec/STATUS.md
mix docs      # generate documentation
```

### Spec

The requirements are in [spec/ex_lwp.spec.md](https://github.com/ErikMejerHansen/ex_lwp/blob/main/spec/ex_lwp.spec.md),
each with an ID such as `FRAME-3`. Tests declare the requirements they
verify with a tag:

```elixir
@tag spec: "FRAME-3"
test "when encoded, then its length takes two bytes and counts both" do
```

Requirements that tests can't fully cover are reviewed by hand and
recorded in [spec/reviews.exs](https://github.com/ErikMejerHansen/ex_lwp/blob/main/spec/reviews.exs).

`mix spec` runs the tests and writes [spec/STATUS.md](https://github.com/ErikMejerHansen/ex_lwp/blob/main/spec/STATUS.md),
which lists each requirement as tested, reviewed, failing or open.
Commit it together with spec and code changes. CI fails when it is out
of date.

### Releasing

1. Bump `@version` in `mix.exs` and merge to `main`.
2. In GitHub, run **Actions → Publish to Hex** on `main` with that
   version. Tick *Dry run* first to check the package without publishing.

The workflow runs all checks, publishes the package and docs to Hex,
and tags the release `vX.Y.Z`. It needs a `HEX_API_KEY` secret in the
`hex` environment (**Settings → Environments**), where you can also add
required reviewers.

## License

MIT, see [LICENSE](https://github.com/ErikMejerHansen/ex_lwp/blob/main/LICENSE).
