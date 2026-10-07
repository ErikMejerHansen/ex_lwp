defmodule ExLWP.Enums do
  @moduledoc """
  The enumerations and bit-fields of the LEGO® Wireless Protocol, mapped to
  atoms.

  ## Enumerations

  | Enum                         | Values |
  | ---------------------------- | ------ |
  | `:message_type`              | `:hub_properties`, `:hub_actions`, `:hub_alerts`, `:hub_attached_io`, `:generic_error`, `:hw_network_commands`, `:go_into_boot_mode`, `:lock_memory`, `:lock_status_request`, `:lock_status`, `:port_information_request`, `:port_mode_information_request`, `:port_input_format_setup_single`, `:port_input_format_setup_combined`, `:port_information`, `:port_mode_information`, `:port_value_single`, `:port_value_combined`, `:port_input_format_single`, `:port_input_format_combined`, `:virtual_port_setup`, `:port_output_command`, `:port_output_command_feedback` |
  | `:hub_property`              | `:advertising_name`, `:button`, `:fw_version`, `:hw_version`, `:rssi`, `:battery_voltage`, `:battery_type`, `:manufacturer_name`, `:radio_firmware_version`, `:lwp_version`, `:system_type_id`, `:hw_network_id`, `:primary_mac_address`, `:secondary_mac_address`, `:hw_network_family` |
  | `:hub_property_operation`    | `:set`, `:enable_updates`, `:disable_updates`, `:reset`, `:request_update`, `:update` |
  | `:hub_action`                | `:switch_off_hub`, `:disconnect`, `:vcc_port_control_on`, `:vcc_port_control_off`, `:activate_busy_indication`, `:reset_busy_indication`, `:shutdown`, `:hub_will_switch_off`, `:hub_will_disconnect`, `:hub_will_go_into_boot_mode` |
  | `:hub_alert`                 | `:low_voltage`, `:high_current`, `:low_signal_strength`, `:over_power_condition` |
  | `:hub_alert_operation`       | `:enable_updates`, `:disable_updates`, `:request_updates`, `:update` |
  | `:alert_status`              | `:ok`, `:alert` |
  | `:io_event`                  | `:detached`, `:attached`, `:attached_virtual` |
  | `:io_type`                   | `:motor`, `:system_train_motor`, `:button`, `:led_light`, `:voltage`, `:current`, `:piezo_tone`, `:rgb_light`, `:external_tilt_sensor`, `:motion_sensor`, `:vision_sensor`, `:external_motor_with_tacho`, `:internal_motor_with_tacho`, `:internal_tilt` |
  | `:error_code`                | `:ack`, `:mack`, `:buffer_overflow`, `:timeout`, `:command_not_recognized`, `:invalid_use`, `:overcurrent`, `:internal_error` |
  | `:hw_network_command`        | `:connection_request`, `:family_request`, `:family_set`, `:join_denied`, `:get_family`, `:family`, `:get_subfamily`, `:subfamily`, `:subfamily_set`, `:get_extended_family`, `:extended_family`, `:extended_family_set`, `:reset_long_press_timing` |
  | `:button_state`              | `:released`, `:pressed` |
  | `:battery_type`              | `:normal`, `:rechargeable` |
  | `:system_type`               | `:wedo_hub`, `:duplo_train`, `:boost_hub`, `:two_port_hub`, `:two_port_handset` |
  | `:lock_status`               | `:ok`, `:not_locked` |
  | `:port_information_type`     | `:port_value`, `:mode_info`, `:possible_mode_combinations` |
  | `:mode_information_type`     | `:name`, `:raw`, `:pct`, `:si`, `:symbol`, `:mapping`, `:internal`, `:motor_bias`, `:capability_bits`, `:value_format` |
  | `:combined_sub_command`      | `:set_mode_dataset_combinations`, `:lock`, `:unlock_and_start_with_multi_update`, `:unlock_and_start_without_multi_update`, `:reset` |
  | `:dataset_type`              | `:int8`, `:int16`, `:int32`, `:float` |
  | `:virtual_port_sub_command`  | `:disconnect`, `:connect` |
  | `:startup`                   | `:buffer_if_necessary`, `:execute_immediately` |
  | `:completion`                | `:no_action`, `:command_feedback` |
  | `:end_state`                 | `:float`, `:hold`, `:brake` |
  | `:tilt_orientation`          | `:bottom`, `:front`, `:back`, `:left`, `:right`, `:top`, `:use_actual_as_bottom` |
  | `:calibration_orientation`   | `:xy`, `:z` |

  Values without a known name are passed through as integers, so decoding
  never fails because of a newer firmware adding enum values.

  ## Bit-fields

  | Bit-field              | Flags |
  | ---------------------- | ----- |
  | `:port_capabilities`   | `:output`, `:input`, `:logical_combinable`, `:logical_synchronizable` |
  | `:mapping`             | `:discrete`, `:relative`, `:absolute`, `:supports_functional_mapping_2`, `:supports_null` |
  | `:use_profile`         | `:acceleration`, `:deceleration` |
  | `:feedback`            | `:buffer_empty_command_in_progress`, `:buffer_empty_command_completed`, `:current_command_discarded`, `:idle`, `:busy_full` |
  | `:device_capabilities` | `:central_role`, `:peripheral_role`, `:lpf2_devices`, `:remote_controller` |
  | `:advertising_status`  | `:can_be_peripheral`, `:can_be_central`, `:request_window`, `:request_connect` |

  Bit-fields are lists of flags. Bits without a known name are passed
  through as their integer value.
  """

  import Bitwise

  @enums %{
    message_type: [
      hub_properties: 0x01,
      hub_actions: 0x02,
      hub_alerts: 0x03,
      hub_attached_io: 0x04,
      generic_error: 0x05,
      hw_network_commands: 0x08,
      go_into_boot_mode: 0x10,
      lock_memory: 0x11,
      lock_status_request: 0x12,
      lock_status: 0x13,
      port_information_request: 0x21,
      port_mode_information_request: 0x22,
      port_input_format_setup_single: 0x41,
      port_input_format_setup_combined: 0x42,
      port_information: 0x43,
      port_mode_information: 0x44,
      port_value_single: 0x45,
      port_value_combined: 0x46,
      port_input_format_single: 0x47,
      port_input_format_combined: 0x48,
      virtual_port_setup: 0x61,
      port_output_command: 0x81,
      port_output_command_feedback: 0x82
    ],
    hub_property: [
      advertising_name: 0x01,
      button: 0x02,
      fw_version: 0x03,
      hw_version: 0x04,
      rssi: 0x05,
      battery_voltage: 0x06,
      battery_type: 0x07,
      manufacturer_name: 0x08,
      radio_firmware_version: 0x09,
      lwp_version: 0x0A,
      system_type_id: 0x0B,
      hw_network_id: 0x0C,
      primary_mac_address: 0x0D,
      secondary_mac_address: 0x0E,
      hw_network_family: 0x0F
    ],
    hub_property_operation: [
      set: 0x01,
      enable_updates: 0x02,
      disable_updates: 0x03,
      reset: 0x04,
      request_update: 0x05,
      update: 0x06
    ],
    hub_action: [
      switch_off_hub: 0x01,
      disconnect: 0x02,
      vcc_port_control_on: 0x03,
      vcc_port_control_off: 0x04,
      activate_busy_indication: 0x05,
      reset_busy_indication: 0x06,
      shutdown: 0x2F,
      hub_will_switch_off: 0x30,
      hub_will_disconnect: 0x31,
      hub_will_go_into_boot_mode: 0x32
    ],
    hub_alert: [
      low_voltage: 0x01,
      high_current: 0x02,
      low_signal_strength: 0x03,
      over_power_condition: 0x04
    ],
    hub_alert_operation: [
      enable_updates: 0x01,
      disable_updates: 0x02,
      request_updates: 0x03,
      update: 0x04
    ],
    alert_status: [ok: 0x00, alert: 0xFF],
    io_event: [detached: 0x00, attached: 0x01, attached_virtual: 0x02],
    io_type: [
      motor: 0x0001,
      system_train_motor: 0x0002,
      button: 0x0005,
      led_light: 0x0008,
      voltage: 0x0014,
      current: 0x0015,
      piezo_tone: 0x0016,
      rgb_light: 0x0017,
      external_tilt_sensor: 0x0022,
      motion_sensor: 0x0023,
      vision_sensor: 0x0025,
      external_motor_with_tacho: 0x0026,
      internal_motor_with_tacho: 0x0027,
      internal_tilt: 0x0028
    ],
    error_code: [
      ack: 0x01,
      mack: 0x02,
      buffer_overflow: 0x03,
      timeout: 0x04,
      command_not_recognized: 0x05,
      invalid_use: 0x06,
      overcurrent: 0x07,
      internal_error: 0x08
    ],
    hw_network_command: [
      connection_request: 0x02,
      family_request: 0x03,
      family_set: 0x04,
      join_denied: 0x05,
      get_family: 0x06,
      family: 0x07,
      get_subfamily: 0x08,
      subfamily: 0x09,
      subfamily_set: 0x0A,
      get_extended_family: 0x0B,
      extended_family: 0x0C,
      extended_family_set: 0x0D,
      reset_long_press_timing: 0x0E
    ],
    button_state: [released: 0x00, pressed: 0x01],
    battery_type: [normal: 0x00, rechargeable: 0x01],
    system_type: [
      wedo_hub: 0b000_00000,
      duplo_train: 0b001_00000,
      boost_hub: 0b010_00000,
      two_port_hub: 0b010_00001,
      two_port_handset: 0b010_00010
    ],
    lock_status: [ok: 0x00, not_locked: 0xFF],
    port_information_type: [port_value: 0x00, mode_info: 0x01, possible_mode_combinations: 0x02],
    mode_information_type: [
      name: 0x00,
      raw: 0x01,
      pct: 0x02,
      si: 0x03,
      symbol: 0x04,
      mapping: 0x05,
      internal: 0x06,
      motor_bias: 0x07,
      capability_bits: 0x08,
      value_format: 0x80
    ],
    combined_sub_command: [
      set_mode_dataset_combinations: 0x01,
      lock: 0x02,
      unlock_and_start_with_multi_update: 0x03,
      unlock_and_start_without_multi_update: 0x04,
      reset: 0x06
    ],
    dataset_type: [int8: 0x00, int16: 0x01, int32: 0x02, float: 0x03],
    virtual_port_sub_command: [disconnect: 0x00, connect: 0x01],
    startup: [buffer_if_necessary: 0x0, execute_immediately: 0x1],
    completion: [no_action: 0x0, command_feedback: 0x1],
    end_state: [float: 0, hold: 126, brake: 127],
    tilt_orientation: [
      bottom: 0,
      front: 1,
      back: 2,
      left: 3,
      right: 4,
      top: 5,
      use_actual_as_bottom: 6
    ],
    calibration_orientation: [xy: 1, z: 2]
  }

  @flags %{
    port_capabilities: [
      output: 0x01,
      input: 0x02,
      logical_combinable: 0x04,
      logical_synchronizable: 0x08
    ],
    mapping: [
      discrete: 0x04,
      relative: 0x08,
      absolute: 0x10,
      supports_functional_mapping_2: 0x40,
      supports_null: 0x80
    ],
    use_profile: [acceleration: 0x01, deceleration: 0x02],
    feedback: [
      buffer_empty_command_in_progress: 0x01,
      buffer_empty_command_completed: 0x02,
      current_command_discarded: 0x04,
      idle: 0x08,
      busy_full: 0x10
    ],
    device_capabilities: [
      central_role: 0x01,
      peripheral_role: 0x02,
      lpf2_devices: 0x04,
      remote_controller: 0x08
    ],
    advertising_status: [
      can_be_peripheral: 0x01,
      can_be_central: 0x02,
      request_window: 0x20,
      request_connect: 0x40
    ]
  }

  @type enum :: atom()
  @type bit_field :: atom()
  @type flags :: [atom() | pos_integer()]

  @doc """
  Returns the named values of `enum` as a keyword list.

      iex> ExLWP.Enums.values(:startup)
      [buffer_if_necessary: 0, execute_immediately: 1]
  """
  @spec values(enum()) :: keyword(non_neg_integer())
  def values(enum), do: Map.fetch!(@enums, enum)

  @doc """
  Converts a name (or a raw integer) to its wire value.

      iex> ExLWP.Enums.to_value(:end_state, :brake)
      127

      iex> ExLWP.Enums.to_value(:end_state, 127)
      127
  """
  @spec to_value(enum(), atom() | non_neg_integer()) :: non_neg_integer()
  def to_value(_enum, value) when is_integer(value), do: value

  def to_value(enum, name) when is_atom(name) do
    case Keyword.fetch(values(enum), name) do
      {:ok, value} -> value
      :error -> raise ArgumentError, "unknown #{enum} value: #{inspect(name)}"
    end
  end

  @doc """
  Converts a wire value to its name, or returns the integer if it has none.

      iex> ExLWP.Enums.to_name(:io_type, 0x0027)
      :internal_motor_with_tacho

      iex> ExLWP.Enums.to_name(:io_type, 0x0042)
      0x0042
  """
  @spec to_name(enum(), non_neg_integer()) :: atom() | non_neg_integer()
  def to_name(enum, value) when is_integer(value) do
    Enum.find_value(values(enum), value, fn {name, v} -> v == value && name end)
  end

  @doc """
  Returns the flags of `bit_field` as a keyword list of flag to bit mask.

      iex> ExLWP.Enums.flags(:use_profile)
      [acceleration: 1, deceleration: 2]
  """
  @spec flags(bit_field()) :: keyword(pos_integer())
  def flags(bit_field), do: Map.fetch!(@flags, bit_field)

  @doc """
  Converts a list of flags (atoms or raw bit masks) to its wire value.

      iex> ExLWP.Enums.to_bits(:use_profile, [:acceleration, :deceleration])
      3
  """
  @spec to_bits(bit_field(), flags()) :: non_neg_integer()
  def to_bits(bit_field, flags) when is_list(flags) do
    Enum.reduce(flags, 0, fn
      flag, bits when is_integer(flag) ->
        bits ||| flag

      flag, bits when is_atom(flag) ->
        case Keyword.fetch(flags(bit_field), flag) do
          {:ok, mask} -> bits ||| mask
          :error -> raise ArgumentError, "unknown #{bit_field} flag: #{inspect(flag)}"
        end
    end)
  end

  @doc """
  Converts a wire value to a list of flags. Bits without a name are
  returned as their integer value.

      iex> ExLWP.Enums.to_flags(:port_capabilities, 0b0110)
      [:input, :logical_combinable]

      iex> ExLWP.Enums.to_flags(:port_capabilities, 0b1000_0001)
      [:output, 0x80]
  """
  @spec to_flags(bit_field(), non_neg_integer()) :: flags()
  def to_flags(bit_field, bits) when is_integer(bits) and bits >= 0 do
    named = for {flag, mask} <- flags(bit_field), (bits &&& mask) != 0, do: flag
    known = Enum.reduce(flags(bit_field), 0, fn {_flag, mask}, acc -> acc ||| mask end)
    unnamed = for bit <- 0..31, mask = 1 <<< bit, (bits &&& mask &&& ~~~known) != 0, do: mask
    named ++ unnamed
  end
end
