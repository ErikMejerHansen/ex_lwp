# Structs for every message of the LEGO Hub Characteristic, see
# https://lego.github.io/lego-ble-wireless-protocol-docs/#message-types
#
# Encoding and decoding lives in ExLWP.Message; these modules only describe
# the shape of each message.

defmodule ExLWP.Message.HubProperty do
  @moduledoc """
  Sets, reads or subscribes to a hub property, or reports its value. (`0x01`)

  `value` is only sent for the `:set` and `:update` operations. Its type
  depends on the property:

  | Property                  | Value |
  | ------------------------- | ----- |
  | `:advertising_name`       | string, at most 14 bytes |
  | `:button`                 | `:pressed` or `:released` |
  | `:fw_version`             | `ExLWP.Version` |
  | `:hw_version`             | `ExLWP.Version` |
  | `:rssi`                   | `-127..0` |
  | `:battery_voltage`        | `0..100` (percent) |
  | `:battery_type`           | `:normal` or `:rechargeable` |
  | `:manufacturer_name`      | string |
  | `:radio_firmware_version` | string |
  | `:lwp_version`            | `ExLWP.Version` (major and minor only) |
  | `:system_type_id`         | `ExLWP.Enums` `:system_type` |
  | `:hw_network_id`          | `0..255` |
  | `:primary_mac_address`    | 6 byte binary |
  | `:secondary_mac_address`  | 6 byte binary |
  | `:hw_network_family`      | `0..8` |

  Values of unknown properties are kept as raw bytes.
  """
  defstruct [:property, :operation, value: nil]

  @type t :: %__MODULE__{
          property: atom() | 0..0xFF,
          operation: atom() | 0..0xFF,
          value: term()
        }
end

defmodule ExLWP.Message.HubAction do
  @moduledoc """
  Asks the hub to do something, or tells that it is about to. (`0x02`)

  See `ExLWP.Enums` `:hub_action` for the actions.
  """
  defstruct [:action]
  @type t :: %__MODULE__{action: atom() | 0..0xFF}
end

defmodule ExLWP.Message.HubAlert do
  @moduledoc """
  Subscribes to, requests or reports a hub alert. (`0x03`)

  `status` (`:ok` or `:alert`) is only sent with the `:update` operation.
  """
  defstruct [:alert, :operation, status: nil]

  @type t :: %__MODULE__{
          alert: atom() | 0..0xFF,
          operation: atom() | 0..0xFF,
          status: :ok | :alert | 0..0xFF | nil
        }
end

defmodule ExLWP.Message.HubAttachedIO do
  @moduledoc """
  Tells that an I/O device was attached to or detached from a port. (`0x04`)

  Which fields are set depends on `event`:

    * `:detached` - only `port`
    * `:attached` - `io_type`, `hardware_revision` and `software_revision`
    * `:attached_virtual` - `io_type`, and the ports it combines in
      `port_a` and `port_b`
  """
  defstruct [
    :port,
    :event,
    io_type: nil,
    hardware_revision: nil,
    software_revision: nil,
    port_a: nil,
    port_b: nil
  ]

  @type t :: %__MODULE__{
          port: 0..0xFF,
          event: :detached | :attached | :attached_virtual,
          io_type: atom() | 0..0xFFFF | nil,
          hardware_revision: ExLWP.Version.t() | non_neg_integer() | nil,
          software_revision: ExLWP.Version.t() | non_neg_integer() | nil,
          port_a: 0..0xFF | nil,
          port_b: 0..0xFF | nil
        }
end

defmodule ExLWP.Message.GenericError do
  @moduledoc """
  Reports an error, or an acknowledgement, for a command. (`0x05`)

  `command_type` is the message type of the command, see `ExLWP.Enums`
  `:message_type`.
  """
  defstruct [:command_type, :error_code]
  @type t :: %__MODULE__{command_type: atom() | 0..0xFF, error_code: atom() | 0..0xFF}
end

defmodule ExLWP.Message.HwNetworkCommand do
  @moduledoc """
  Sets up hubs in a network without a smart device. (`0x08`)

  Which fields are set depends on `command`:

    * `:connection_request` - `button`, `:pressed` or `:released`
    * `:family_set`, `:family` - `family`, `0..8`
    * `:subfamily_set`, `:subfamily` - `subfamily`, `1..7`
    * `:extended_family_set`, `:extended_family` - `family` and `subfamily`
    * all other commands - none
  """
  defstruct [:command, button: nil, family: nil, subfamily: nil]

  @type t :: %__MODULE__{
          command: atom() | 0..0xFF,
          button: :pressed | :released | 0..0xFF | nil,
          family: 0..0xF | nil,
          subfamily: 0..0x7 | nil
        }
end

defmodule ExLWP.Message.GoIntoBootMode do
  @moduledoc "Puts the hub in boot loader mode for a firmware update. (`0x10`)"
  defstruct []
  @type t :: %__MODULE__{}
end

defmodule ExLWP.Message.LockMemory do
  @moduledoc "Locks the hub's memory. For production use only. (`0x11`)"
  defstruct []
  @type t :: %__MODULE__{}
end

defmodule ExLWP.Message.LockStatusRequest do
  @moduledoc "Asks for the memory lock status. For production use only. (`0x12`)"
  defstruct []
  @type t :: %__MODULE__{}
end

defmodule ExLWP.Message.LockStatus do
  @moduledoc "Reply to `LockStatusRequest`: `:ok` or `:not_locked`. (`0x13`)"
  defstruct [:status]
  @type t :: %__MODULE__{status: :ok | :not_locked | 0..0xFF}
end

defmodule ExLWP.Message.PortInformationRequest do
  @moduledoc """
  Asks for a port's value, mode info or possible mode combinations. (`0x21`)
  """
  defstruct [:port, :information_type]
  @type t :: %__MODULE__{port: 0..0xFF, information_type: atom() | 0..0xFF}
end

defmodule ExLWP.Message.PortModeInformationRequest do
  @moduledoc """
  Asks for information about one mode of a port. (`0x22`)

  See `ExLWP.Enums` `:mode_information_type` for the information types.
  """
  defstruct [:port, :mode, :information_type]
  @type t :: %__MODULE__{port: 0..0xFF, mode: 0..0xFF, information_type: atom() | 0..0xFF}
end

defmodule ExLWP.Message.PortInputFormatSetupSingle do
  @moduledoc """
  Sets the mode of a port, and when it should send value updates. (`0x41`)

  A new value is sent when it has changed by `delta_interval` or more.
  """
  defstruct [:port, :mode, delta_interval: 1, notification_enabled: true]

  @type t :: %__MODULE__{
          port: 0..0xFF,
          mode: 0..0xFF,
          delta_interval: 0..0xFFFFFFFF,
          notification_enabled: boolean()
        }
end

defmodule ExLWP.Message.PortInputFormatSetupCombined do
  @moduledoc """
  Sets up a port to report several modes at once (CombinedMode). (`0x42`)

  `combination_index` and `mode_datasets` (a list of `{mode, dataset}`) are
  only sent with the `:set_mode_dataset_combinations` sub command.
  """
  defstruct [:port, :sub_command, combination_index: nil, mode_datasets: nil]

  @type t :: %__MODULE__{
          port: 0..0xFF,
          sub_command: atom() | 0..0xFF,
          combination_index: 0..0xFF | nil,
          mode_datasets: [{0..0xF, 0..0xF}] | nil
        }
end

defmodule ExLWP.Message.PortInformation do
  @moduledoc """
  Reply to `PortInformationRequest`. (`0x43`)

  For `:mode_info`, `capabilities` is a list of `ExLWP.Enums`
  `:port_capabilities` flags, and `input_modes` and `output_modes` are lists
  of mode numbers.

  For `:possible_mode_combinations`, `mode_combinations` is a list of
  combinations, each a list of mode numbers.
  """
  defstruct [
    :port,
    :information_type,
    capabilities: nil,
    total_mode_count: nil,
    input_modes: nil,
    output_modes: nil,
    mode_combinations: nil
  ]

  @type t :: %__MODULE__{
          port: 0..0xFF,
          information_type: :mode_info | :possible_mode_combinations,
          capabilities: ExLWP.Enums.flags() | nil,
          total_mode_count: 0..0xFF | nil,
          input_modes: [0..15] | nil,
          output_modes: [0..15] | nil,
          mode_combinations: [[0..15]] | nil
        }
end

defmodule ExLWP.Message.PortModeInformation do
  @moduledoc """
  Reply to `PortModeInformationRequest`. (`0x44`)

  The type of `value` depends on `information_type`:

  | Information type   | Value |
  | ------------------ | ----- |
  | `:name`            | string, at most 11 bytes |
  | `:raw`             | `{min, max}` floats |
  | `:pct`             | `{min, max}` floats |
  | `:si`              | `{min, max}` floats |
  | `:symbol`          | string, at most 5 bytes |
  | `:mapping`         | `%{input: flags, output: flags}`, see `ExLWP.Enums` `:mapping` |
  | `:motor_bias`      | `0..100` (percent) |
  | `:capability_bits` | 6 byte binary |
  | `:value_format`    | `ExLWP.ValueFormat` |

  Values of other information types are kept as raw bytes.
  """
  defstruct [:port, :mode, :information_type, :value]

  @type t :: %__MODULE__{
          port: 0..0xFF,
          mode: 0..0xFF,
          information_type: atom() | 0..0xFF,
          value: term()
        }
end

defmodule ExLWP.Message.PortValueSingle do
  @moduledoc """
  A port's current value, in the format of its mode. (`0x45`)

  `value` holds the raw bytes, since their format depends on the port's
  mode: decode them with `ExLWP.ValueFormat.decode/2`.

  A message can hold values for more ports. `value` then holds every byte
  after the first port ID; split it with `ExLWP.ValueFormat.size/1`.
  """
  defstruct [:port, :value]
  @type t :: %__MODULE__{port: 0..0xFF, value: binary()}
end

defmodule ExLWP.Message.PortValueCombined do
  @moduledoc """
  The values of a port in CombinedMode. (`0x46`)

  `mode_datasets` lists the positions, from the combined mode setup, of the
  mode/datasets whose values follow in `value`, lowest first. `value` holds
  the raw bytes: decode them with `ExLWP.ValueFormat`.
  """
  defstruct [:port, :mode_datasets, :value]
  @type t :: %__MODULE__{port: 0..0xFF, mode_datasets: [0..15], value: binary()}
end

defmodule ExLWP.Message.PortInputFormatSingle do
  @moduledoc "Reply to `PortInputFormatSetupSingle`, with the port's new setup. (`0x47`)"
  defstruct [:port, :mode, :delta_interval, :notification_enabled]

  @type t :: %__MODULE__{
          port: 0..0xFF,
          mode: 0..0xFF,
          delta_interval: 0..0xFFFFFFFF,
          notification_enabled: boolean()
        }
end

defmodule ExLWP.Message.PortInputFormatCombined do
  @moduledoc """
  Reply to `PortInputFormatSetupCombined`. (`0x48`)

  `mode_datasets` lists the positions of the mode/datasets that were set up.
  An empty list means the combined mode was reset.
  """
  defstruct [:port, :combination_index, :multi_update, :mode_datasets]

  @type t :: %__MODULE__{
          port: 0..0xFF,
          combination_index: 0..0xF,
          multi_update: boolean(),
          mode_datasets: [0..15]
        }
end

defmodule ExLWP.Message.VirtualPortSetup do
  @moduledoc """
  Combines two ports into a virtual port, or splits one. (`0x61`)

    * `:connect` - combines `port_a` and `port_b`
    * `:disconnect` - splits the virtual `port`
  """
  defstruct [:sub_command, port: nil, port_a: nil, port_b: nil]

  @type t :: %__MODULE__{
          sub_command: :connect | :disconnect,
          port: 0..0xFF | nil,
          port_a: 0..0xFF | nil,
          port_b: 0..0xFF | nil
        }
end

defmodule ExLWP.Message.PortOutputCommand do
  @moduledoc """
  Sends an output command, such as starting a motor, to a port. (`0x81`)

  `command` is one of the `ExLWP.Output` sub command structs.

    * `startup` - `:execute_immediately` or `:buffer_if_necessary`
    * `completion` - `:command_feedback` to get a
      `ExLWP.Message.PortOutputCommandFeedback`, or `:no_action`
  """
  defstruct [
    :port,
    :command,
    startup: :execute_immediately,
    completion: :command_feedback
  ]

  @type t :: %__MODULE__{
          port: 0..0xFF,
          command: ExLWP.Output.t(),
          startup: :execute_immediately | :buffer_if_necessary | 0..0xF,
          completion: :command_feedback | :no_action | 0..0xF
        }
end

defmodule ExLWP.Message.PortOutputCommandFeedback do
  @moduledoc """
  Tells the progress of output commands, for one or more ports. (`0x82`)

  `feedback` is a list of `{port, flags}`, see `ExLWP.Enums` `:feedback` for
  the flags.
  """
  defstruct feedback: []
  @type t :: %__MODULE__{feedback: [{0..0xFF, ExLWP.Enums.flags()}]}
end
