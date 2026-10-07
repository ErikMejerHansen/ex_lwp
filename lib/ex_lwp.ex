defmodule ExLWP do
  @moduledoc """
  Stateless encoder and decoder for the LEGO® Wireless Protocol 3.0, used by
  the Powered Up hubs and documented at
  <https://lego.github.io/lego-ble-wireless-protocol-docs/>.

  > #### Not affiliated with LEGO {: .warning}
  >
  > ExLWP is an independent project. It is not affiliated with, sponsored,
  > authorized or endorsed by The LEGO Group. LEGO® and Powered Up are
  > trademarks of The LEGO Group.

  ExLWP only turns messages into bytes and bytes into messages. It holds no
  state and starts no processes; you bring the BLE connection. Write
  messages to, and subscribe to notifications from, the characteristic
  `characteristic_uuid/0` of the service `service_uuid/0`.

  ## Encoding

  Build a message with `ExLWP.Messages` (or a struct from
  `ExLWP.Message.*`) and encode it, header included:

      iex> ExLWP.Messages.request_hub_property(:advertising_name) |> ExLWP.encode()
      <<0x05, 0x00, 0x01, 0x01, 0x05>>

  Raw message bytes, starting with the message type, work too:

      iex> ExLWP.encode(<<0x01, 0x01, 0x05>>)
      <<0x05, 0x00, 0x01, 0x01, 0x05>>

  ## Decoding

      iex> ExLWP.decode(<<0x05, 0x00, 0x04, 0x01, 0x00>>)
      {:ok, %ExLWP.Message.HubAttachedIO{port: 1, event: :detached}}

  A BLE notification normally holds one message, but `decode_stream/1`
  copes with partial or several messages. Keep the returned rest for the
  next notification:

      iex> {messages, rest} = ExLWP.decode_stream(<<0x04, 0x00, 0x02, 0x30, 0x05>>)
      iex> messages
      [{:ok, %ExLWP.Message.HubAction{action: :hub_will_switch_off}}]
      iex> rest
      <<0x05>>

  ## Layers

    * `ExLWP.Messages` - functions that build messages
    * `ExLWP.Message` - message structs to/from raw bytes
    * `ExLWP.Output` - the sub commands of port output commands
    * `ExLWP.Header` - raw bytes to/from messages with the common header
    * `ExLWP.ValueFormat` - decodes port values
    * `ExLWP.Version` - version numbers
    * `ExLWP.Advertisement` - the manufacturer data hubs advertise
    * `ExLWP.Enums` - protocol enumerations and bit-fields as atoms
  """

  alias ExLWP.{Header, Message}

  @doc """
  Returns the UUID of the LEGO Hub Service.

      iex> ExLWP.service_uuid()
      "00001623-1212-efde-1623-785feabcd123"
  """
  @spec service_uuid() :: String.t()
  def service_uuid, do: "00001623-1212-efde-1623-785feabcd123"

  @doc """
  Returns the UUID of the LEGO Hub Characteristic, which carries all
  messages.

      iex> ExLWP.characteristic_uuid()
      "00001624-1212-efde-1623-785feabcd123"
  """
  @spec characteristic_uuid() :: String.t()
  def characteristic_uuid, do: "00001624-1212-efde-1623-785feabcd123"

  @doc """
  Encodes a message struct, or raw message bytes, into a message with the
  common header.

  ## Options

    * `:hub_id` - `0` (default), see `ExLWP.Header.pack/2`.
  """
  @spec encode(Message.t() | binary(), keyword()) :: binary()
  def encode(message, opts \\ [])
  def encode(bytes, opts) when is_binary(bytes), do: Header.pack(bytes, opts)

  def encode(message, opts) when is_struct(message),
    do: message |> Message.encode() |> encode(opts)

  @doc """
  Decodes a single message, header included, into a message struct.
  """
  @spec decode(binary()) ::
          {:ok, Message.t()} | {:error, Message.decode_error() | :invalid_length}
  def decode(bytes) when is_binary(bytes) do
    with {:ok, _hub_id, message} <- Header.unpack(bytes), do: Message.decode(message)
  end

  @doc """
  Decodes every complete message in `stream`.

  Returns `{results, rest}`, where `results` holds one `decode/1` result per
  message and `rest` holds the bytes of an incomplete message. Prepend
  `rest` to the next bytes you receive.
  """
  @spec decode_stream(binary()) :: {[{:ok, Message.t()} | {:error, term()}], binary()}
  def decode_stream(stream) when is_binary(stream) do
    {messages, rest} = Header.split(stream)
    {Enum.map(messages, &decode/1), rest}
  end
end
