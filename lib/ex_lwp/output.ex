defmodule ExLWP.Output do
  @moduledoc """
  Encodes and decodes the sub commands of a
  `ExLWP.Message.PortOutputCommand`.

  You rarely need this module directly: build commands with
  `ExLWP.Messages`, and `ExLWP.Message` uses this module for their sub
  commands.

      iex> ExLWP.Output.encode(%ExLWP.Output.StartSpeed{speed: 50, max_power: 100})
      <<0x07, 50, 100, 0x00>>

      iex> ExLWP.Output.decode(<<0x07, 50, 100, 0x00>>)
      {:ok, %ExLWP.Output.StartSpeed{speed: 50, max_power: 100, use_profile: []}}

  See [Port Output Command](https://lego.github.io/lego-ble-wireless-protocol-docs/#port-output-command).
  """

  import ExLWP.Fields
  import Bitwise

  alias ExLWP.Enums

  alias ExLWP.Output.{
    GotoAbsolutePosition,
    GotoAbsolutePositionSynced,
    PresetEncoderSynced,
    SetAccTime,
    SetDecTime,
    StartPowerSynced,
    StartSpeed,
    StartSpeedForDegrees,
    StartSpeedForDegreesSynced,
    StartSpeedForTime,
    StartSpeedForTimeSynced,
    StartSpeedSynced,
    Unknown,
    WriteDirect,
    WriteDirectModeData
  }

  @documented [0x02, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x14, 0x50, 0x51]

  @type t ::
          StartPowerSynced.t()
          | SetAccTime.t()
          | SetDecTime.t()
          | StartSpeed.t()
          | StartSpeedSynced.t()
          | StartSpeedForTime.t()
          | StartSpeedForTimeSynced.t()
          | StartSpeedForDegrees.t()
          | StartSpeedForDegreesSynced.t()
          | GotoAbsolutePosition.t()
          | GotoAbsolutePositionSynced.t()
          | PresetEncoderSynced.t()
          | WriteDirect.t()
          | WriteDirectModeData.t()
          | Unknown.t()

  @typedoc "-100..100 percent, or `:float` (0) or `:brake` (127)"
  @type power :: -100..100 | 127 | :float | :brake

  @type end_state :: :float | :hold | :brake | 0..0xFF

  @doc """
  Encodes a sub command, starting with its sub command ID.

  Raises `ArgumentError` if a field does not fit.
  """
  @spec encode(t()) :: binary()
  def encode(command), do: command |> encode_fields() |> IO.iodata_to_binary()

  defp encode_fields(%StartPowerSynced{} = c),
    do: [0x02, power(c.power1, :power1), power(c.power2, :power2)]

  defp encode_fields(%SetAccTime{} = c),
    do: [0x05, time(c.time, 0..10_000), profile(c.profile)]

  defp encode_fields(%SetDecTime{} = c),
    do: [0x06, time(c.time, 0..10_000), profile(c.profile)]

  defp encode_fields(%StartSpeed{} = c),
    do: [0x07, speed(c.speed, :speed), max_power(c.max_power), use_profile(c.use_profile)]

  defp encode_fields(%StartSpeedSynced{} = c) do
    [
      0x08,
      speed(c.speed1, :speed1),
      speed(c.speed2, :speed2),
      max_power(c.max_power),
      use_profile(c.use_profile)
    ]
  end

  defp encode_fields(%StartSpeedForTime{} = c),
    do: [0x09, time(c.time, 0..0x7FFF), speed(c.speed, :speed) | ending(c)]

  defp encode_fields(%StartSpeedForTimeSynced{} = c) do
    [0x0A, time(c.time, 0..0x7FFF), speed(c.speed_l, :speed_l), speed(c.speed_r, :speed_r)] ++
      ending(c)
  end

  defp encode_fields(%StartSpeedForDegrees{} = c),
    do: [0x0B, s32(c.degrees, :degrees), speed(c.speed, :speed) | ending(c)]

  defp encode_fields(%StartSpeedForDegreesSynced{} = c) do
    [0x0C, s32(c.degrees, :degrees), speed(c.speed_l, :speed_l), speed(c.speed_r, :speed_r)] ++
      ending(c)
  end

  defp encode_fields(%GotoAbsolutePosition{} = c),
    do: [0x0D, s32(c.abs_pos, :abs_pos), speed(c.speed, :speed) | ending(c)]

  defp encode_fields(%GotoAbsolutePositionSynced{} = c) do
    [0x0E, s32(c.abs_pos1, :abs_pos1), s32(c.abs_pos2, :abs_pos2), speed(c.speed, :speed)] ++
      ending(c)
  end

  defp encode_fields(%PresetEncoderSynced{} = c),
    do: [0x14, s32(c.left_position, :left_position), s32(c.right_position, :right_position)]

  defp encode_fields(%WriteDirect{payload: payload}) do
    payload = binary(payload, :payload)
    [0x50, payload, checksum(payload)]
  end

  defp encode_fields(%WriteDirectModeData{} = c),
    do: [0x51, u8(c.mode, :mode), binary(c.payload, :payload)]

  defp encode_fields(%Unknown{} = c),
    do: [u8(c.sub_command, :sub_command), binary(c.payload, :payload)]

  # MaxPower, EndState and UseProfile, at the end of most motor commands
  defp ending(c) do
    [
      max_power(c.max_power),
      enum(:end_state, c.end_state, :end_state),
      use_profile(c.use_profile)
    ]
  end

  @doc """
  Decodes a sub command. Returns `:error` if it doesn't match the
  documented layout.

  Sub commands that are not documented are returned as
  `ExLWP.Output.Unknown`.
  """
  @spec decode(binary()) :: {:ok, t()} | :error
  def decode(<<0x02, power1::signed, power2::signed>>),
    do: {:ok, %StartPowerSynced{power1: power1, power2: power2}}

  def decode(<<0x05, time::little-signed-16, profile::signed>>),
    do: {:ok, %SetAccTime{time: time, profile: profile}}

  def decode(<<0x06, time::little-signed-16, profile::signed>>),
    do: {:ok, %SetDecTime{time: time, profile: profile}}

  def decode(<<0x07, speed::signed, max_power::signed, profile>>) do
    {:ok, %StartSpeed{speed: speed, max_power: max_power, use_profile: from_profile(profile)}}
  end

  def decode(<<0x08, speed1::signed, speed2::signed, max_power::signed, profile>>) do
    {:ok,
     %StartSpeedSynced{
       speed1: speed1,
       speed2: speed2,
       max_power: max_power,
       use_profile: from_profile(profile)
     }}
  end

  def decode(<<0x09, time::little-signed-16, speed::signed, rest::binary-size(3)>>),
    do: ending(%StartSpeedForTime{time: time, speed: speed}, rest)

  def decode(
        <<0x0A, time::little-signed-16, speed_l::signed, speed_r::signed, rest::binary-size(3)>>
      ),
      do: ending(%StartSpeedForTimeSynced{time: time, speed_l: speed_l, speed_r: speed_r}, rest)

  def decode(<<0x0B, degrees::little-signed-32, speed::signed, rest::binary-size(3)>>),
    do: ending(%StartSpeedForDegrees{degrees: degrees, speed: speed}, rest)

  def decode(
        <<0x0C, degrees::little-signed-32, speed_l::signed, speed_r::signed,
          rest::binary-size(3)>>
      ) do
    ending(
      %StartSpeedForDegreesSynced{degrees: degrees, speed_l: speed_l, speed_r: speed_r},
      rest
    )
  end

  def decode(<<0x0D, abs_pos::little-signed-32, speed::signed, rest::binary-size(3)>>),
    do: ending(%GotoAbsolutePosition{abs_pos: abs_pos, speed: speed}, rest)

  def decode(
        <<0x0E, abs_pos1::little-signed-32, abs_pos2::little-signed-32, speed::signed,
          rest::binary-size(3)>>
      ) do
    ending(
      %GotoAbsolutePositionSynced{abs_pos1: abs_pos1, abs_pos2: abs_pos2, speed: speed},
      rest
    )
  end

  def decode(<<0x14, left::little-signed-32, right::little-signed-32>>),
    do: {:ok, %PresetEncoderSynced{left_position: left, right_position: right}}

  def decode(<<0x50, bytes::binary>>) when byte_size(bytes) >= 1 do
    payload_size = byte_size(bytes) - 1
    <<payload::binary-size(payload_size), sum>> = bytes

    if <<sum>> == checksum(payload), do: {:ok, %WriteDirect{payload: payload}}, else: :error
  end

  def decode(<<0x51, mode, payload::binary>>),
    do: {:ok, %WriteDirectModeData{mode: mode, payload: payload}}

  def decode(<<id, payload::binary>>) when id not in @documented,
    do: {:ok, %Unknown{sub_command: id, payload: payload}}

  def decode(_bytes), do: :error

  defp ending(command, <<max_power::signed, end_state, profile>>) do
    {:ok,
     %{
       command
       | max_power: max_power,
         end_state: Enums.to_name(:end_state, end_state),
         use_profile: from_profile(profile)
     }}
  end

  @doc """
  Returns the checksum WriteDirect adds to its payload.

      iex> ExLWP.Output.checksum(<<0xD4, 0x11>>)
      <<0x3A>>
  """
  @spec checksum(binary()) :: <<_::8>>
  def checksum(payload) when is_binary(payload) do
    <<for(<<byte <- payload>>, reduce: 0xFF, do: (sum -> bxor(sum, byte)))>>
  end

  defp power(:float, _field), do: <<0>>
  defp power(:brake, _field), do: <<127>>
  defp power(value, _field) when value in -100..100 or value == 127, do: <<value::signed>>

  defp power(value, field),
    do:
      raise(ArgumentError, "#{field} must be -100..100, :float or :brake, got: #{inspect(value)}")

  defp speed(value, _field) when value in -100..100, do: <<value::signed>>

  defp speed(value, field),
    do: raise(ArgumentError, "#{field} must be -100..100, got: #{inspect(value)}")

  defp max_power(value) when value in 0..100, do: <<value>>

  defp max_power(value),
    do: raise(ArgumentError, "max_power must be 0..100, got: #{inspect(value)}")

  defp time(value, range) do
    if value in range,
      do: <<value::little-signed-16>>,
      else: raise(ArgumentError, "time must be #{inspect(range)} ms, got: #{inspect(value)}")
  end

  defp profile(value), do: s8(value, :profile)
  defp use_profile(value), do: flags(:use_profile, value, :use_profile)
  defp from_profile(bits), do: Enums.to_flags(:use_profile, bits)
end
