defmodule ExLWP.Version do
  @moduledoc """
  Version numbers, as sent in hub properties and attached I/O messages.

  Firmware and hardware versions use the 32 bit
  [Version Number Encoding](https://lego.github.io/lego-ble-wireless-protocol-docs/#version-number-encoding):
  major, minor, bug fixing and build numbers in BCD.

      iex> ExLWP.Version.decode(0x17371510)
      %ExLWP.Version{major: 1, minor: 7, bugfix: 37, build: 1510}

  The LEGO Wireless Protocol version uses the 16 bit
  [LWP Version Number Encoding](https://lego.github.io/lego-ble-wireless-protocol-docs/#lwp-version-number-encoding),
  with only a major and minor number:

      iex> ExLWP.Version.decode_lwp(0x0300)
      %ExLWP.Version{major: 3, minor: 0}

  Values that are not valid BCD are returned as integers, so nothing is lost.

  Versions print the way LEGO presents them:

      iex> to_string(%ExLWP.Version{major: 1, minor: 7, bugfix: 37, build: 1510})
      "1.7.37.1510"
  """

  import Bitwise

  defstruct major: 0, minor: 0, bugfix: nil, build: nil

  @type t :: %__MODULE__{
          major: non_neg_integer(),
          minor: non_neg_integer(),
          bugfix: non_neg_integer() | nil,
          build: non_neg_integer() | nil
        }

  @doc """
  Decodes a 32 bit version number. Returns the integer if it is not a
  valid version.
  """
  @spec decode(non_neg_integer()) :: t() | non_neg_integer()
  def decode(value) when value in 0..0x7FFFFFFF do
    <<0::1, major::3, minor::4, bugfix::8, build::16>> = <<value::32>>

    with {:ok, minor} <- from_bcd(minor, 1),
         {:ok, bugfix} <- from_bcd(bugfix, 2),
         {:ok, build} <- from_bcd(build, 4) do
      %__MODULE__{major: major, minor: minor, bugfix: bugfix, build: build}
    else
      :error -> value
    end
  end

  def decode(value) when is_integer(value), do: value

  @doc """
  Encodes a 32 bit version number. Integers are passed through.

      iex> ExLWP.Version.encode(%ExLWP.Version{major: 1, minor: 7, bugfix: 37, build: 1510})
      0x17371510

  Raises `ArgumentError` if a number does not fit.
  """
  @spec encode(t() | non_neg_integer()) :: non_neg_integer()
  def encode(value) when is_integer(value), do: value

  def encode(%__MODULE__{major: major, minor: minor, bugfix: bugfix, build: build})
      when major in 0..7 and minor in 0..9 and bugfix in 0..99 and build in 0..9999 do
    major <<< 28 ||| to_bcd(minor) <<< 24 ||| to_bcd(bugfix) <<< 16 ||| to_bcd(build)
  end

  def encode(version), do: raise(ArgumentError, "not a valid version: #{inspect(version)}")

  @doc """
  Decodes a 16 bit LWP version number. Returns the integer if it is not a
  valid version.
  """
  @spec decode_lwp(0..0xFFFF) :: t() | 0..0xFFFF
  def decode_lwp(value) when value in 0..0xFFFF do
    with {:ok, major} <- from_bcd(value >>> 8, 2),
         {:ok, minor} <- from_bcd(value &&& 0xFF, 2) do
      %__MODULE__{major: major, minor: minor}
    else
      :error -> value
    end
  end

  @doc """
  Encodes a 16 bit LWP version number. Integers are passed through.

      iex> ExLWP.Version.encode_lwp(%ExLWP.Version{major: 3, minor: 0})
      0x0300

  Raises `ArgumentError` if a number does not fit.
  """
  @spec encode_lwp(t() | 0..0xFFFF) :: 0..0xFFFF
  def encode_lwp(value) when is_integer(value), do: value

  def encode_lwp(%__MODULE__{major: major, minor: minor, bugfix: nil, build: nil})
      when major in 0..99 and minor in 0..99,
      do: to_bcd(major) <<< 8 ||| to_bcd(minor)

  def encode_lwp(version),
    do: raise(ArgumentError, "not a valid LWP version: #{inspect(version)}")

  defp from_bcd(value, digits) do
    nibbles = for shift <- (digits - 1)..0//-1, do: value >>> (shift * 4) &&& 0xF

    if Enum.all?(nibbles, &(&1 <= 9)),
      do: {:ok, Enum.reduce(nibbles, 0, &(&2 * 10 + &1))},
      else: :error
  end

  defp to_bcd(value) do
    value
    |> Integer.digits()
    |> Enum.reduce(0, &(&2 <<< 4 ||| &1))
  end

  defimpl String.Chars do
    def to_string(%{major: major, minor: minor, bugfix: nil, build: nil}),
      do: "#{major}.#{pad(minor, 2)}"

    def to_string(%{major: major, minor: minor, bugfix: bugfix, build: build}),
      do: "#{major}.#{minor}.#{pad(bugfix, 2)}.#{pad(build, 4)}"

    defp pad(number, width), do: number |> Integer.to_string() |> String.pad_leading(width, "0")
  end
end
