defmodule ExLWP.Header do
  @moduledoc """
  The Common Message Header that starts every message: length, hub ID and
  message type.

  The length counts the whole message, header included. Up to 127 it takes
  one byte. Above that it takes two: the low 7 bits with bit 7 set, then the
  remaining bits.

      iex> ExLWP.Header.encode_length(5)
      <<5>>

      iex> ExLWP.Header.encode_length(128)
      <<0x80, 0x01>>

  The message type is the first byte of the raw message bytes handled by
  `ExLWP.Message`, so this module only adds and removes the length and hub
  ID.

  See [Common Message Header](https://lego.github.io/lego-ble-wireless-protocol-docs/#common-message-header).
  """

  import Bitwise

  @max_length 0x7FFF

  @doc """
  Adds the length and hub ID to raw message bytes (message type and
  payload).

      iex> ExLWP.Header.pack(<<0x01, 0x01, 0x05>>)
      <<0x05, 0x00, 0x01, 0x01, 0x05>>

  ## Options

    * `:hub_id` - the hub ID, `0` by default. The protocol doesn't use it
      yet, and says to always send `0`.

  Raises `ArgumentError` if the message is longer than the protocol allows.
  """
  @spec pack(binary(), keyword()) :: binary()
  def pack(<<_type, _payload::binary>> = message, opts \\ []) do
    hub_id = Keyword.get(opts, :hub_id, 0)

    unless hub_id in 0..0xFF do
      raise ArgumentError, "hub_id must be 0..255, got: #{inspect(hub_id)}"
    end

    # The length counts itself, so a message one byte too long for a 1 byte
    # length grows by one more byte for the 2 byte length.
    length =
      case byte_size(message) + 2 do
        short when short <= 0x7F -> short
        long -> long + 1
      end

    <<encode_length(length)::binary, hub_id, message::binary>>
  end

  @doc """
  Removes the length and hub ID from a single message.

  Returns `{:ok, hub_id, message}`, where `message` holds the message type
  and payload.

      iex> ExLWP.Header.unpack(<<0x05, 0x00, 0x01, 0x01, 0x05>>)
      {:ok, 0, <<0x01, 0x01, 0x05>>}

      iex> ExLWP.Header.unpack(<<0x09, 0x00, 0x01, 0x01, 0x05>>)
      {:error, :invalid_length}
  """
  @spec unpack(binary()) :: {:ok, 0..0xFF, binary()} | {:error, :invalid_length}
  def unpack(frame) when is_binary(frame) do
    with {:ok, length, <<hub_id, message::binary>>} <- decode_length(frame),
         true <- length == byte_size(frame),
         <<_type, _::binary>> <- message do
      {:ok, hub_id, message}
    else
      _ -> {:error, :invalid_length}
    end
  end

  @doc """
  Splits a stream of bytes into complete messages.

  Returns `{messages, rest}`, where `rest` holds the start of an incomplete
  message. Prepend it to the next bytes you receive.

      iex> ExLWP.Header.split(<<0x04, 0x00, 0x02, 0x01, 0x05, 0x00>>)
      {[<<0x04, 0x00, 0x02, 0x01>>], <<0x05, 0x00>>}

  If a length field is too small to hold a header, the stream can no longer
  be split reliably. The rest of the stream is then returned as a single
  message, which fails to decode.
  """
  @spec split(binary()) :: {[binary()], binary()}
  def split(stream) when is_binary(stream), do: split(stream, [])

  defp split(stream, messages) do
    case decode_length(stream) do
      {:ok, length, _} when length < 3 ->
        {Enum.reverse([stream | messages]), <<>>}

      {:ok, length, _} when byte_size(stream) >= length ->
        <<message::binary-size(length), rest::binary>> = stream
        split(rest, [message | messages])

      _incomplete ->
        {Enum.reverse(messages), stream}
    end
  end

  @doc """
  Encodes a message length.

  Raises `ArgumentError` for lengths the protocol can't express.
  """
  @spec encode_length(1..0x7FFF) :: binary()
  def encode_length(length) when length in 1..0x7F, do: <<length>>

  def encode_length(length) when length in 0x80..@max_length,
    do: <<1::1, length &&& 0x7F::7, length >>> 7>>

  def encode_length(length),
    do: raise(ArgumentError, "message length must be 1..#{@max_length}, got: #{inspect(length)}")

  @doc """
  Decodes the length at the start of `bytes`.

  Returns `{:ok, length, rest}`, or `:incomplete` if `bytes` is too short.

      iex> ExLWP.Header.decode_length(<<0x81, 0x01, 0x00>>)
      {:ok, 129, <<0x00>>}
  """
  @spec decode_length(binary()) :: {:ok, non_neg_integer(), binary()} | :incomplete
  def decode_length(<<0::1, length::7, rest::binary>>), do: {:ok, length, rest}
  def decode_length(<<1::1, low::7, high, rest::binary>>), do: {:ok, high <<< 7 ||| low, rest}
  def decode_length(_bytes), do: :incomplete
end
