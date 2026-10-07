defmodule ExLWP.ValueFormat do
  @moduledoc """
  The format of a port mode's values, and functions to decode them.

  The size of a value in a `ExLWP.Message.PortValueSingle` or
  `ExLWP.Message.PortValueCombined` depends on the mode the port is in, so
  ExLWP hands those values over as raw bytes. Ask the hub for the mode's
  format with a Port Mode Information Request for `:value_format`, then use
  the returned `ExLWP.ValueFormat` to decode the bytes:

      iex> format = %ExLWP.ValueFormat{datasets: 1, type: :int32, figures: 4, decimals: 0}
      iex> ExLWP.ValueFormat.decode(format, <<0x68, 0x01, 0x00, 0x00>>)
      {:ok, [360]}

  Values are signed and little endian. `figures` and `decimals` are display
  hints: decoded values are not scaled. Floats that are not numbers decode
  to `:nan`, `:infinity` or `:neg_infinity`.

  See [Value Format](https://lego.github.io/lego-ble-wireless-protocol-docs/#value-format).
  """

  alias ExLWP.Enums

  defstruct datasets: 1, type: :int8, figures: 0, decimals: 0

  @type t :: %__MODULE__{
          datasets: 0..0xFF,
          type: :int8 | :int16 | :int32 | :float | 0..0xFF,
          figures: 0..0xFF,
          decimals: 0..0xFF
        }

  @doc """
  Returns the size in bytes of the values in this format.

      iex> ExLWP.ValueFormat.size(%ExLWP.ValueFormat{datasets: 3, type: :int16})
      6
  """
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{datasets: datasets, type: type}), do: datasets * dataset_size(type)

  @doc """
  Decodes the values in `bytes`.

  Returns `{:error, :size_mismatch}` if `bytes` does not hold exactly
  `size/1` bytes. For a Port Value message holding values for several
  ports, split it with `size/1` first.
  """
  @spec decode(t(), binary()) ::
          {:ok, [number() | :nan | :infinity | :neg_infinity]} | {:error, :size_mismatch}
  def decode(%__MODULE__{type: type} = format, bytes) when is_binary(bytes) do
    if byte_size(bytes) == size(format) and type in [:int8, :int16, :int32, :float] do
      value_size = dataset_size(type)
      {:ok, for(<<value::binary-size(value_size) <- bytes>>, do: decode_value(type, value))}
    else
      {:error, :size_mismatch}
    end
  end

  @doc """
  Encodes values in this format, e.g. to simulate a hub.

      iex> format = %ExLWP.ValueFormat{datasets: 2, type: :int8}
      iex> ExLWP.ValueFormat.encode(format, [-1, 100])
      <<0xFF, 0x64>>

  Raises `ArgumentError` if the number of values doesn't match `datasets`
  or a value doesn't fit.
  """
  @spec encode(t(), [number()]) :: binary()
  def encode(%__MODULE__{datasets: datasets, type: type}, values)
      when is_list(values) and length(values) == datasets do
    for value <- values, into: <<>>, do: encode_value(type, value)
  end

  def encode(format, values) do
    raise ArgumentError,
          "expected #{inspect(format.datasets)} values, got: #{inspect(values)}"
  end

  @doc false
  def from_bytes(<<datasets, type, figures, decimals>>) do
    %__MODULE__{
      datasets: datasets,
      type: Enums.to_name(:dataset_type, type),
      figures: figures,
      decimals: decimals
    }
  end

  @doc false
  def to_bytes(%__MODULE__{} = format) do
    for field <- [
          format.datasets,
          Enums.to_value(:dataset_type, format.type),
          format.figures,
          format.decimals
        ],
        into: <<>> do
      unless field in 0..0xFF,
        do: raise(ArgumentError, "invalid value format: #{inspect(format)}")

      <<field>>
    end
  end

  defp dataset_size(:int8), do: 1
  defp dataset_size(:int16), do: 2
  defp dataset_size(:int32), do: 4
  defp dataset_size(:float), do: 4
  defp dataset_size(_unknown), do: 0

  defp decode_value(:float, <<value::float-little-32>>), do: value

  defp decode_value(:float, bytes) do
    case <<:binary.decode_unsigned(bytes, :little)::32>> do
      <<0::1, 0xFF, 0::23>> -> :infinity
      <<1::1, 0xFF, 0::23>> -> :neg_infinity
      _ -> :nan
    end
  end

  defp decode_value(_int, bytes), do: decode_signed(bytes)

  defp decode_signed(bytes) do
    bits = bit_size(bytes)
    <<value::little-signed-size(bits)>> = bytes
    value
  end

  defp encode_value(:float, value) when is_number(value), do: <<value::float-little-32>>

  defp encode_value(type, value) when is_integer(value) and type in [:int8, :int16, :int32] do
    bits = dataset_size(type) * 8
    limit = Integer.pow(2, bits - 1)

    unless value in -limit..(limit - 1)//1 do
      raise ArgumentError, "#{inspect(value)} does not fit in #{type}"
    end

    <<value::little-signed-size(bits)>>
  end

  defp encode_value(type, value),
    do: raise(ArgumentError, "can't encode #{inspect(value)} as #{inspect(type)}")
end
