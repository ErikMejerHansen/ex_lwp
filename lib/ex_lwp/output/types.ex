# Structs for the sub commands of a Port Output Command, see
# https://lego.github.io/lego-ble-wireless-protocol-docs/#port-output-command
#
# Encoding and decoding lives in ExLWP.Output. The "Synced" sub commands are
# the ones the documentation lists with two values (e.g. Power1, Power2),
# for the two motors of a virtual port.
#
# Speeds and powers are percentages, -100..100, negative being counter
# clockwise. A power of 127 brakes and 0 floats; `:brake` and `:float` can be
# used instead. `use_profile` is a list of `:acceleration` and
# `:deceleration`, `end_state` one of `:float`, `:hold` or `:brake`.

defmodule ExLWP.Output.StartPowerSynced do
  @moduledoc "Turns on both motors of a virtual port, unregulated. (`0x02`)"
  defstruct [:power1, :power2]
  @type t :: %__MODULE__{power1: ExLWP.Output.power(), power2: ExLWP.Output.power()}
end

defmodule ExLWP.Output.SetAccTime do
  @moduledoc "Sets the time in ms to accelerate from 0 to 100% for a profile. (`0x05`)"
  defstruct [:time, profile: 0]
  @type t :: %__MODULE__{time: 0..10_000, profile: 0..0x7F}
end

defmodule ExLWP.Output.SetDecTime do
  @moduledoc "Sets the time in ms to decelerate from 100% to 0 for a profile. (`0x06`)"
  defstruct [:time, profile: 0]
  @type t :: %__MODULE__{time: 0..10_000, profile: 0..0x7F}
end

defmodule ExLWP.Output.StartSpeed do
  @moduledoc "Runs the motor at `speed`. A speed of 0 holds its position. (`0x07`)"
  defstruct [:speed, max_power: 100, use_profile: []]

  @type t :: %__MODULE__{
          speed: -100..100,
          max_power: 0..100,
          use_profile: ExLWP.Enums.flags()
        }
end

defmodule ExLWP.Output.StartSpeedSynced do
  @moduledoc "Runs both motors of a virtual port, each at its own speed. (`0x08`)"
  defstruct [:speed1, :speed2, max_power: 100, use_profile: []]

  @type t :: %__MODULE__{
          speed1: -100..100,
          speed2: -100..100,
          max_power: 0..100,
          use_profile: ExLWP.Enums.flags()
        }
end

defmodule ExLWP.Output.StartSpeedForTime do
  @moduledoc "Runs the motor at `speed` for `time` ms. (`0x09`)"
  defstruct [:time, :speed, max_power: 100, end_state: :brake, use_profile: []]

  @type t :: %__MODULE__{
          time: 0..0x7FFF,
          speed: -100..100,
          max_power: 0..100,
          end_state: ExLWP.Output.end_state(),
          use_profile: ExLWP.Enums.flags()
        }
end

defmodule ExLWP.Output.StartSpeedForTimeSynced do
  @moduledoc "Runs both motors of a virtual port for `time` ms. (`0x0A`)"
  defstruct [:time, :speed_l, :speed_r, max_power: 100, end_state: :brake, use_profile: []]

  @type t :: %__MODULE__{
          time: 0..0x7FFF,
          speed_l: -100..100,
          speed_r: -100..100,
          max_power: 0..100,
          end_state: ExLWP.Output.end_state(),
          use_profile: ExLWP.Enums.flags()
        }
end

defmodule ExLWP.Output.StartSpeedForDegrees do
  @moduledoc """
  Runs the motor for `degrees` at `speed`. The sign of `speed` sets the
  direction. (`0x0B`)
  """
  defstruct [:degrees, :speed, max_power: 100, end_state: :brake, use_profile: []]

  @type t :: %__MODULE__{
          degrees: 0..0x7FFFFFFF,
          speed: -100..100,
          max_power: 0..100,
          end_state: ExLWP.Output.end_state(),
          use_profile: ExLWP.Enums.flags()
        }
end

defmodule ExLWP.Output.StartSpeedForDegreesSynced do
  @moduledoc """
  Runs both motors of a virtual port for `degrees`, the average of the two
  motors. (`0x0C`)
  """
  defstruct [:degrees, :speed_l, :speed_r, max_power: 100, end_state: :brake, use_profile: []]

  @type t :: %__MODULE__{
          degrees: 0..10_000_000,
          speed_l: -100..100,
          speed_r: -100..100,
          max_power: 0..100,
          end_state: ExLWP.Output.end_state(),
          use_profile: ExLWP.Enums.flags()
        }
end

defmodule ExLWP.Output.GotoAbsolutePosition do
  @moduledoc "Turns the motor to the absolute position `abs_pos`. (`0x0D`)"
  defstruct [:abs_pos, :speed, max_power: 100, end_state: :brake, use_profile: []]

  @type t :: %__MODULE__{
          abs_pos: integer(),
          speed: -100..100,
          max_power: 0..100,
          end_state: ExLWP.Output.end_state(),
          use_profile: ExLWP.Enums.flags()
        }
end

defmodule ExLWP.Output.GotoAbsolutePositionSynced do
  @moduledoc "Turns both motors of a virtual port to absolute positions. (`0x0E`)"
  defstruct [:abs_pos1, :abs_pos2, :speed, max_power: 100, end_state: :brake, use_profile: []]

  @type t :: %__MODULE__{
          abs_pos1: integer(),
          abs_pos2: integer(),
          speed: -100..100,
          max_power: 0..100,
          end_state: ExLWP.Output.end_state(),
          use_profile: ExLWP.Enums.flags()
        }
end

defmodule ExLWP.Output.PresetEncoderSynced do
  @moduledoc """
  Sets the encoders of both motors of a virtual port, leaving the virtual
  encoder as it is. (`0x14`)
  """
  defstruct [:left_position, :right_position]
  @type t :: %__MODULE__{left_position: integer(), right_position: integer()}
end

defmodule ExLWP.Output.WriteDirect do
  @moduledoc """
  Writes bytes directly to the device on the port. (`0x50`)

  The checksum is added when encoding, and checked and removed when
  decoding.
  """
  defstruct payload: <<>>
  @type t :: %__MODULE__{payload: binary()}
end

defmodule ExLWP.Output.WriteDirectModeData do
  @moduledoc """
  Sets the device on the port to `mode`, and writes `payload` to it. (`0x51`)

  Many documented commands, like StartPower(Power) or SetRgbColorNo, are
  sent this way. `ExLWP.Messages` has functions for them.
  """
  defstruct [:mode, payload: <<>>]
  @type t :: %__MODULE__{mode: 0..0xFF, payload: binary()}
end

defmodule ExLWP.Output.Unknown do
  @moduledoc "A sub command that is not in the documentation."
  defstruct [:sub_command, payload: <<>>]
  @type t :: %__MODULE__{sub_command: 0..0xFF, payload: binary()}
end
