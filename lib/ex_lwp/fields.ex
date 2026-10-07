defmodule ExLWP.Fields do
  @moduledoc false
  # Encodes message fields, checking that each value fits its field.
  # Binary syntax would silently truncate values that don't fit.

  import Bitwise

  alias ExLWP.Enums

  def u8(value, _field) when value in 0..0xFF, do: <<value>>
  def u8(value, field), do: invalid!(field, "0..255", value)

  def s8(value, _field) when value in -0x80..0x7F, do: <<value::signed>>
  def s8(value, field), do: invalid!(field, "-128..127", value)

  def u16(value, _field) when value in 0..0xFFFF, do: <<value::little-16>>
  def u16(value, field), do: invalid!(field, "0..65535", value)

  def s16(value, _field) when value in -0x8000..0x7FFF, do: <<value::little-signed-16>>
  def s16(value, field), do: invalid!(field, "-32768..32767", value)

  def u32(value, _field) when value in 0..0xFFFFFFFF, do: <<value::little-32>>
  def u32(value, field), do: invalid!(field, "0..4294967295", value)

  def s32(value, _field) when value in -0x80000000..0x7FFFFFFF, do: <<value::little-signed-32>>
  def s32(value, field), do: invalid!(field, "-2147483648..2147483647", value)

  def bool(true, _field), do: <<1>>
  def bool(false, _field), do: <<0>>
  def bool(value, field), do: invalid!(field, "a boolean", value)

  def enum(enum, value, field), do: enum |> Enums.to_value(value) |> u8(field)
  def enum16(enum, value, field), do: enum |> Enums.to_value(value) |> u16(field)

  def flags(bit_field, value, field) when is_list(value),
    do: bit_field |> Enums.to_bits(value) |> u8(field)

  def flags(_bit_field, value, field), do: invalid!(field, "a list of flags", value)

  # A bit mask of up to 16 positions, e.g. modes, as a sorted list
  def positions(value, field) when is_list(value) do
    if Enum.all?(value, &(&1 in 0..15)) do
      value |> Enum.reduce(0, &(&2 ||| 1 <<< &1)) |> u16(field)
    else
      invalid!(field, "a list of positions 0..15", value)
    end
  end

  def positions(value, field), do: invalid!(field, "a list of positions 0..15", value)

  def to_positions(mask), do: for(bit <- 0..15, (mask &&& 1 <<< bit) != 0, do: bit)

  def string(value, max, _field) when is_binary(value) and byte_size(value) <= max, do: value
  def string(value, max, field), do: invalid!(field, "a string of at most #{max} bytes", value)

  def binary(value, size, _field) when is_binary(value) and byte_size(value) == size, do: value
  def binary(value, size, field), do: invalid!(field, "#{size} bytes", value)

  def binary(value, _field) when is_binary(value), do: value
  def binary(value, field), do: invalid!(field, "a binary", value)

  def float32(value, _field) when is_number(value), do: <<value::float-little-32>>
  def float32(value, field), do: invalid!(field, "a number", value)

  # Strings may be padded with zeros
  def from_string(bytes), do: bytes |> :binary.split(<<0>>) |> hd()

  def from_bool(0), do: {:ok, false}
  def from_bool(1), do: {:ok, true}
  def from_bool(_), do: :error

  defp invalid!(field, expected, value) do
    raise ArgumentError, "#{field} must be #{expected}, got: #{inspect(value)}"
  end
end
