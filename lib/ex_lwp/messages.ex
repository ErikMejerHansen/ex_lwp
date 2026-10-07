defmodule ExLWP.Messages do
  @moduledoc """
  Functions for building the messages a client sends to the hub.

  Each function returns a message struct, ready for `ExLWP.encode/2`:

      iex> ExLWP.Messages.start_speed(0, 50) |> ExLWP.encode()
      <<0x09, 0x00, 0x81, 0x00, 0x11, 0x07, 50, 100, 0x00>>

  Messages sent by the hub (replies and updates) are just structs: build
  them with `%ExLWP.Message.HubAttachedIO{...}` if you need to.

  ## Output command options

  Functions that build a `ExLWP.Message.PortOutputCommand` take these
  options:

    * `:startup` - `:execute_immediately` (default) or `:buffer_if_necessary`
    * `:completion` - `:command_feedback` (default) or `:no_action`

  Motor commands also take, where the protocol has them:

    * `:max_power` - `0..100`, default `100`
    * `:end_state` - `:brake` (default), `:hold` or `:float`
    * `:use_profile` - a list of `:acceleration` and `:deceleration`,
      default `[]`. Set the profiles with `set_acc_time/4` and
      `set_dec_time/4`.

  Speeds and powers are percentages, `-100..100`. Negative values turn
  counter clockwise.
  """

  import ExLWP.Fields, only: [u8: 2, s8: 2, s32: 2]

  alias ExLWP.Message
  alias ExLWP.Output

  @motor_options [:max_power, :end_state, :use_profile]

  # Hub properties

  @doc """
  Asks the hub for the value of a property, see `ExLWP.Enums` `:hub_property`.

      iex> ExLWP.Messages.request_hub_property(:battery_voltage)
      %ExLWP.Message.HubProperty{property: :battery_voltage, operation: :request_update}
  """
  @spec request_hub_property(atom()) :: Message.HubProperty.t()
  def request_hub_property(property), do: hub_property(property, :request_update)

  @doc "Asks the hub to send an update whenever a property changes."
  @spec enable_hub_property_updates(atom()) :: Message.HubProperty.t()
  def enable_hub_property_updates(property), do: hub_property(property, :enable_updates)

  @doc "Stops the updates enabled with `enable_hub_property_updates/1`."
  @spec disable_hub_property_updates(atom()) :: Message.HubProperty.t()
  def disable_hub_property_updates(property), do: hub_property(property, :disable_updates)

  @doc "Resets a property, e.g. the advertising name to its default."
  @spec reset_hub_property(atom()) :: Message.HubProperty.t()
  def reset_hub_property(property), do: hub_property(property, :reset)

  @doc """
  Sets a property. Only `:advertising_name`, `:hw_network_id` and
  `:hw_network_family` can be set.
  """
  @spec set_hub_property(atom(), term()) :: Message.HubProperty.t()
  def set_hub_property(property, value),
    do: %Message.HubProperty{property: property, operation: :set, value: value}

  @doc "Renames the hub. The name may be at most 14 bytes."
  @spec set_advertising_name(String.t()) :: Message.HubProperty.t()
  def set_advertising_name(name), do: set_hub_property(:advertising_name, name)

  defp hub_property(property, operation),
    do: %Message.HubProperty{property: property, operation: operation}

  # Hub actions and alerts

  @doc "Asks the hub to perform an action, see `ExLWP.Enums` `:hub_action`."
  @spec hub_action(atom()) :: Message.HubAction.t()
  def hub_action(action), do: %Message.HubAction{action: action}

  @doc "Switches the hub off."
  @spec switch_off() :: Message.HubAction.t()
  def switch_off, do: hub_action(:switch_off_hub)

  @doc "Disconnects from the hub."
  @spec disconnect() :: Message.HubAction.t()
  def disconnect, do: hub_action(:disconnect)

  @doc "Asks the hub to send an update whenever an alert changes."
  @spec enable_hub_alert(atom()) :: Message.HubAlert.t()
  def enable_hub_alert(alert), do: %Message.HubAlert{alert: alert, operation: :enable_updates}

  @doc "Stops the updates enabled with `enable_hub_alert/1`."
  @spec disable_hub_alert(atom()) :: Message.HubAlert.t()
  def disable_hub_alert(alert), do: %Message.HubAlert{alert: alert, operation: :disable_updates}

  @doc "Asks for the current state of an alert, see `ExLWP.Enums` `:hub_alert`."
  @spec request_hub_alert(atom()) :: Message.HubAlert.t()
  def request_hub_alert(alert), do: %Message.HubAlert{alert: alert, operation: :request_updates}

  # H/W networks and firmware updates

  @doc """
  Builds a H/W NetWork command. See `ExLWP.Message.HwNetworkCommand` for
  the fields each command takes.

      iex> ExLWP.Messages.hw_network_command(:extended_family_set, family: 5, subfamily: 3)
      %ExLWP.Message.HwNetworkCommand{command: :extended_family_set, family: 5, subfamily: 3}
  """
  @spec hw_network_command(atom(), keyword()) :: Message.HwNetworkCommand.t()
  def hw_network_command(command, fields \\ []),
    do: struct!(Message.HwNetworkCommand, [command: command] ++ fields)

  @doc "Puts the hub in boot loader mode, to update its firmware."
  @spec go_into_boot_mode() :: Message.GoIntoBootMode.t()
  def go_into_boot_mode, do: %Message.GoIntoBootMode{}

  @doc "Locks the hub's memory. For production use only."
  @spec lock_memory() :: Message.LockMemory.t()
  def lock_memory, do: %Message.LockMemory{}

  @doc "Asks for the memory lock status. For production use only."
  @spec lock_status_request() :: Message.LockStatusRequest.t()
  def lock_status_request, do: %Message.LockStatusRequest{}

  # Port information and input setup

  @doc """
  Asks for information about a port: `:port_value`, `:mode_info` or
  `:possible_mode_combinations`.
  """
  @spec port_information_request(0..0xFF, atom()) :: Message.PortInformationRequest.t()
  def port_information_request(port, information_type),
    do: %Message.PortInformationRequest{port: port, information_type: information_type}

  @doc """
  Asks for information about a mode of a port, see `ExLWP.Enums`
  `:mode_information_type`.
  """
  @spec port_mode_information_request(0..0xFF, 0..0xFF, atom()) ::
          Message.PortModeInformationRequest.t()
  def port_mode_information_request(port, mode, information_type) do
    %Message.PortModeInformationRequest{
      port: port,
      mode: mode,
      information_type: information_type
    }
  end

  @doc """
  Sets the mode of a port. With `notify` on, the hub sends a value update
  whenever the value changes by `delta_interval` or more.

      iex> ExLWP.Messages.port_input_format_setup(1, 2, 5) |> ExLWP.encode()
      <<0x0A, 0x00, 0x41, 0x01, 0x02, 0x05, 0x00, 0x00, 0x00, 0x01>>
  """
  @spec port_input_format_setup(0..0xFF, 0..0xFF, 0..0xFFFFFFFF, boolean()) ::
          Message.PortInputFormatSetupSingle.t()
  def port_input_format_setup(port, mode, delta_interval \\ 1, notify \\ true) do
    %Message.PortInputFormatSetupSingle{
      port: port,
      mode: mode,
      delta_interval: delta_interval,
      notification_enabled: notify
    }
  end

  @doc """
  Locks a port for a combined mode setup. Then set up each mode with
  `port_input_format_setup/4`, choose them with `combined_mode_set/3` and
  finish with `combined_mode_unlock/2`.
  """
  @spec combined_mode_lock(0..0xFF) :: Message.PortInputFormatSetupCombined.t()
  def combined_mode_lock(port), do: combined(port, :lock)

  @doc """
  Chooses the mode/datasets of a combined mode, as `{mode, dataset}` tuples,
  for the combination at `combination_index` of the port's possible mode
  combinations.

      iex> ExLWP.Messages.combined_mode_set(1, 0, [{1, 0}, {2, 0}]) |> ExLWP.Message.encode()
      <<0x42, 0x01, 0x01, 0x00, 0x10, 0x20>>
  """
  @spec combined_mode_set(0..0xFF, 0..0xFF, [{0..15, 0..15}]) ::
          Message.PortInputFormatSetupCombined.t()
  def combined_mode_set(port, combination_index, mode_datasets) do
    %Message.PortInputFormatSetupCombined{
      port: port,
      sub_command: :set_mode_dataset_combinations,
      combination_index: combination_index,
      mode_datasets: mode_datasets
    }
  end

  @doc """
  Unlocks a port after a combined mode setup and starts it. With
  `multi_update` on, an update of the first mode/dataset sends all values.
  """
  @spec combined_mode_unlock(0..0xFF, boolean()) :: Message.PortInputFormatSetupCombined.t()
  def combined_mode_unlock(port, multi_update \\ true) do
    if multi_update,
      do: combined(port, :unlock_and_start_with_multi_update),
      else: combined(port, :unlock_and_start_without_multi_update)
  end

  @doc "Resets a port from combined mode to mode 0."
  @spec combined_mode_reset(0..0xFF) :: Message.PortInputFormatSetupCombined.t()
  def combined_mode_reset(port), do: combined(port, :reset)

  defp combined(port, sub_command),
    do: %Message.PortInputFormatSetupCombined{port: port, sub_command: sub_command}

  @doc """
  Combines two ports into a virtual port, e.g. to drive two motors in sync.
  The hub replies with a `ExLWP.Message.HubAttachedIO` for the new port.
  """
  @spec virtual_port_connect(0..0xFF, 0..0xFF) :: Message.VirtualPortSetup.t()
  def virtual_port_connect(port_a, port_b),
    do: %Message.VirtualPortSetup{sub_command: :connect, port_a: port_a, port_b: port_b}

  @doc "Splits a virtual port."
  @spec virtual_port_disconnect(0..0xFF) :: Message.VirtualPortSetup.t()
  def virtual_port_disconnect(port),
    do: %Message.VirtualPortSetup{sub_command: :disconnect, port: port}

  # Output commands

  @doc """
  Builds a Port Output Command from an `ExLWP.Output` sub command.

  Takes the `:startup` and `:completion` options.
  """
  @spec port_output_command(0..0xFF, Output.t(), keyword()) :: Message.PortOutputCommand.t()
  def port_output_command(port, command, opts \\ []) do
    %Message.PortOutputCommand{
      port: port,
      command: command,
      startup: Keyword.get(opts, :startup, :execute_immediately),
      completion: Keyword.get(opts, :completion, :command_feedback)
    }
  end

  @doc """
  Turns a motor on at `power`, unregulated. `0` (or `:float`) lets it run
  free, `:brake` brakes.
  """
  @spec start_power(0..0xFF, Output.power(), keyword()) :: Message.PortOutputCommand.t()
  def start_power(port, power, opts \\ []) do
    value =
      case power do
        :float ->
          0

        :brake ->
          127

        power when power in -100..100 or power == 127 ->
          power

        other ->
          raise ArgumentError, "power must be -100..100, :float or :brake, got: #{inspect(other)}"
      end

    write_direct_mode_data(port, 0, <<value::signed>>, opts)
  end

  @doc "Turns on both motors of a virtual port, unregulated."
  @spec start_power_synced(0..0xFF, Output.power(), Output.power(), keyword()) ::
          Message.PortOutputCommand.t()
  def start_power_synced(port, power1, power2, opts \\ []),
    do: output(port, %Output.StartPowerSynced{power1: power1, power2: power2}, opts)

  @doc "Sets the acceleration time, in ms from 0 to 100%, of a profile."
  @spec set_acc_time(0..0xFF, 0..10_000, 0..127, keyword()) :: Message.PortOutputCommand.t()
  def set_acc_time(port, time, profile \\ 0, opts \\ []),
    do: output(port, %Output.SetAccTime{time: time, profile: profile}, opts)

  @doc "Sets the deceleration time, in ms from 100% to 0, of a profile."
  @spec set_dec_time(0..0xFF, 0..10_000, 0..127, keyword()) :: Message.PortOutputCommand.t()
  def set_dec_time(port, time, profile \\ 0, opts \\ []),
    do: output(port, %Output.SetDecTime{time: time, profile: profile}, opts)

  @doc "Runs a motor at `speed`. A speed of 0 holds its position."
  @spec start_speed(0..0xFF, -100..100, keyword()) :: Message.PortOutputCommand.t()
  def start_speed(port, speed, opts \\ []),
    do: motor(port, %Output.StartSpeed{speed: speed}, opts)

  @doc "Runs both motors of a virtual port, each at its own speed."
  @spec start_speed_synced(0..0xFF, -100..100, -100..100, keyword()) ::
          Message.PortOutputCommand.t()
  def start_speed_synced(port, speed1, speed2, opts \\ []),
    do: motor(port, %Output.StartSpeedSynced{speed1: speed1, speed2: speed2}, opts)

  @doc "Runs a motor at `speed` for `time` ms."
  @spec start_speed_for_time(0..0xFF, 0..0x7FFF, -100..100, keyword()) ::
          Message.PortOutputCommand.t()
  def start_speed_for_time(port, time, speed, opts \\ []),
    do: motor(port, %Output.StartSpeedForTime{time: time, speed: speed}, opts)

  @doc "Runs both motors of a virtual port for `time` ms."
  @spec start_speed_for_time_synced(0..0xFF, 0..0x7FFF, -100..100, -100..100, keyword()) ::
          Message.PortOutputCommand.t()
  def start_speed_for_time_synced(port, time, speed_l, speed_r, opts \\ []) do
    command = %Output.StartSpeedForTimeSynced{time: time, speed_l: speed_l, speed_r: speed_r}
    motor(port, command, opts)
  end

  @doc """
  Runs a motor for `degrees` at `speed`. The sign of `speed` sets the
  direction.

      iex> ExLWP.Messages.start_speed_for_degrees(0, 360, -50) |> ExLWP.encode()
      <<0x0E, 0x00, 0x81, 0x00, 0x11, 0x0B, 0x68, 0x01, 0x00, 0x00, 0xCE, 100, 127, 0x00>>
  """
  @spec start_speed_for_degrees(0..0xFF, non_neg_integer(), -100..100, keyword()) ::
          Message.PortOutputCommand.t()
  def start_speed_for_degrees(port, degrees, speed, opts \\ []),
    do: motor(port, %Output.StartSpeedForDegrees{degrees: degrees, speed: speed}, opts)

  @doc """
  Runs both motors of a virtual port for `degrees`, counted as the average
  of the two motors.
  """
  @spec start_speed_for_degrees_synced(
          0..0xFF,
          non_neg_integer(),
          -100..100,
          -100..100,
          keyword()
        ) ::
          Message.PortOutputCommand.t()
  def start_speed_for_degrees_synced(port, degrees, speed_l, speed_r, opts \\ []) do
    command = %Output.StartSpeedForDegreesSynced{
      degrees: degrees,
      speed_l: speed_l,
      speed_r: speed_r
    }

    motor(port, command, opts)
  end

  @doc "Turns a motor to the absolute position `abs_pos`, in degrees."
  @spec goto_absolute_position(0..0xFF, integer(), -100..100, keyword()) ::
          Message.PortOutputCommand.t()
  def goto_absolute_position(port, abs_pos, speed, opts \\ []),
    do: motor(port, %Output.GotoAbsolutePosition{abs_pos: abs_pos, speed: speed}, opts)

  @doc "Turns both motors of a virtual port to absolute positions."
  @spec goto_absolute_position_synced(0..0xFF, integer(), integer(), -100..100, keyword()) ::
          Message.PortOutputCommand.t()
  def goto_absolute_position_synced(port, abs_pos1, abs_pos2, speed, opts \\ []) do
    command = %Output.GotoAbsolutePositionSynced{
      abs_pos1: abs_pos1,
      abs_pos2: abs_pos2,
      speed: speed
    }

    motor(port, command, opts)
  end

  @doc """
  Sets a motor's encoder to `position`; `0` resets it. On a virtual port it
  sets the virtual encoder and both motors' encoders. Stops the motor.
  """
  @spec preset_encoder(0..0xFF, integer(), keyword()) :: Message.PortOutputCommand.t()
  def preset_encoder(port, position, opts \\ []),
    do: write_direct_mode_data(port, 2, s32(position, :position), opts)

  @doc """
  Sets the encoders of both motors of a virtual port, leaving the virtual
  encoder as it is. Stops the motors.
  """
  @spec preset_encoder_synced(0..0xFF, integer(), integer(), keyword()) ::
          Message.PortOutputCommand.t()
  def preset_encoder_synced(port, left_position, right_position, opts \\ []) do
    command = %Output.PresetEncoderSynced{
      left_position: left_position,
      right_position: right_position
    }

    output(port, command, opts)
  end

  @doc "Presets the impact count (mode 3) of a tilt sensor."
  @spec tilt_impact_preset(0..0xFF, non_neg_integer(), keyword()) :: Message.PortOutputCommand.t()
  def tilt_impact_preset(port, value, opts \\ []),
    do: write_direct_mode_data(port, 3, s32(value, :value), opts)

  @doc """
  Sets which side of a tilt sensor is its bottom (mode 5). See `ExLWP.Enums`
  `:tilt_orientation`.
  """
  @spec tilt_config_orientation(0..0xFF, atom() | 0..6, keyword()) ::
          Message.PortOutputCommand.t()
  def tilt_config_orientation(port, orientation, opts \\ []) do
    value = ExLWP.Enums.to_value(:tilt_orientation, orientation)
    write_direct_mode_data(port, 5, s8(value, :orientation), opts)
  end

  @doc """
  Sets the impact threshold (`0..127`) of a tilt sensor, and the minimum
  time between bumps in 10 ms steps (`1..127`) (mode 6).
  """
  @spec tilt_config_impact(0..0xFF, 0..127, 1..127, keyword()) :: Message.PortOutputCommand.t()
  def tilt_config_impact(port, impact_threshold, bump_holdoff, opts \\ []) do
    payload = s8(impact_threshold, :impact_threshold) <> s8(bump_holdoff, :bump_holdoff)
    write_direct_mode_data(port, 6, payload, opts)
  end

  @doc """
  Tells a tilt sensor how it is mounted, `:xy` (laying flat) or `:z`
  (standing). For factory calibration.
  """
  @spec tilt_factory_calibration(0..0xFF, :xy | :z, keyword()) :: Message.PortOutputCommand.t()
  def tilt_factory_calibration(port, orientation, opts \\ []) do
    value = ExLWP.Enums.to_value(:calibration_orientation, orientation)
    write_direct(port, <<0xD4>> <> s8(value, :orientation) <> "Calib-Sensor", opts)
  end

  @doc "Resets, or zero sets, the device on a port."
  @spec generic_zero_set_hardware(0..0xFF, keyword()) :: Message.PortOutputCommand.t()
  def generic_zero_set_hardware(port, opts \\ []), do: write_direct(port, <<0xD4, 0x11>>, opts)

  @doc "Sets an RGB light to color number `color_no` (`0..10`)."
  @spec set_rgb_color_no(0..0xFF, 0..10, keyword()) :: Message.PortOutputCommand.t()
  def set_rgb_color_no(port, color_no, opts \\ []),
    do: write_direct_mode_data(port, 0, s8(color_no, :color_no), opts)

  @doc "Sets an RGB light to a color mixed from red, green and blue (`0..255`)."
  @spec set_rgb_colors(0..0xFF, 0..255, 0..255, 0..255, keyword()) ::
          Message.PortOutputCommand.t()
  def set_rgb_colors(port, red, green, blue, opts \\ []) do
    payload =
      for {field, value} <- [red: red, green: green, blue: blue], into: <<>>, do: u8(value, field)

    write_direct_mode_data(port, 1, payload, opts)
  end

  @doc """
  Writes bytes directly to the device on a port. The checksum is added for
  you.
  """
  @spec write_direct(0..0xFF, binary(), keyword()) :: Message.PortOutputCommand.t()
  def write_direct(port, payload, opts \\ []),
    do: output(port, %Output.WriteDirect{payload: payload}, opts)

  @doc """
  Sets the device on a port to `mode`, and writes `payload` to it.

      iex> ExLWP.Messages.write_direct_mode_data(0, 1, <<0x30, 0x47, 0x55>>) |> ExLWP.Message.encode()
      <<0x81, 0x00, 0x11, 0x51, 0x01, 0x30, 0x47, 0x55>>
  """
  @spec write_direct_mode_data(0..0xFF, 0..0xFF, binary(), keyword()) ::
          Message.PortOutputCommand.t()
  def write_direct_mode_data(port, mode, payload, opts \\ []),
    do: output(port, %Output.WriteDirectModeData{mode: mode, payload: payload}, opts)

  defp output(port, command, opts),
    do: port_output_command(port, command, Keyword.take(opts, [:startup, :completion]))

  defp motor(port, command, opts) do
    options =
      opts
      |> Keyword.take(@motor_options)
      |> Enum.filter(fn {key, _} -> Map.has_key?(command, key) end)

    output(port, struct!(command, options), opts)
  end
end
