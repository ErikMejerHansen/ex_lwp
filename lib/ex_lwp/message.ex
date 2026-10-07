defmodule ExLWP.Message do
  @moduledoc """
  Converts message structs to and from their raw bytes: the message type
  and payload, without the length and hub ID of the common header.

  Every message of the
  [LEGO® Wireless Protocol](https://lego.github.io/lego-ble-wireless-protocol-docs/#message-types)
  has a struct under `ExLWP.Message.*`. Encoding and decoding works in both
  directions for all of them, so the library can also be used to simulate a
  hub.

  Use `ExLWP.encode/2` and `ExLWP.decode/1` to include the header.

      iex> ExLWP.Message.encode(%ExLWP.Message.PortInformationRequest{port: 0, information_type: :mode_info})
      <<0x21, 0x00, 0x01>>

      iex> ExLWP.Message.decode(<<0x21, 0x00, 0x01>>)
      {:ok, %ExLWP.Message.PortInformationRequest{port: 0, information_type: :mode_info}}
  """

  import ExLWP.Fields

  alias ExLWP.{Enums, Output, ValueFormat, Version}

  alias ExLWP.Message.{
    GenericError,
    GoIntoBootMode,
    HubAction,
    HubAlert,
    HubAttachedIO,
    HubProperty,
    HwNetworkCommand,
    LockMemory,
    LockStatus,
    LockStatusRequest,
    PortInformation,
    PortInformationRequest,
    PortInputFormatCombined,
    PortInputFormatSetupCombined,
    PortInputFormatSetupSingle,
    PortInputFormatSingle,
    PortModeInformation,
    PortModeInformationRequest,
    PortOutputCommand,
    PortOutputCommandFeedback,
    PortValueCombined,
    PortValueSingle,
    VirtualPortSetup
  }

  @messages %{
    0x01 => HubProperty,
    0x02 => HubAction,
    0x03 => HubAlert,
    0x04 => HubAttachedIO,
    0x05 => GenericError,
    0x08 => HwNetworkCommand,
    0x10 => GoIntoBootMode,
    0x11 => LockMemory,
    0x12 => LockStatusRequest,
    0x13 => LockStatus,
    0x21 => PortInformationRequest,
    0x22 => PortModeInformationRequest,
    0x41 => PortInputFormatSetupSingle,
    0x42 => PortInputFormatSetupCombined,
    0x43 => PortInformation,
    0x44 => PortModeInformation,
    0x45 => PortValueSingle,
    0x46 => PortValueCombined,
    0x47 => PortInputFormatSingle,
    0x48 => PortInputFormatCombined,
    0x61 => VirtualPortSetup,
    0x81 => PortOutputCommand,
    0x82 => PortOutputCommandFeedback
  }

  @boot_safety_string "LPF2-Boot"
  @lock_safety_string "Lock-Mem"

  # Hub property values that are strings
  @string_properties [:advertising_name, :manufacturer_name, :radio_firmware_version]

  @type t :: struct()
  @type decode_error :: :empty | {:unknown_message, 0..0xFF} | {:malformed, module()}

  @doc """
  Returns the message type of a message struct or module.

      iex> ExLWP.Message.id(ExLWP.Message.PortOutputCommand)
      0x81
  """
  @spec id(t() | module()) :: 0..0xFF
  def id(%module{}), do: id(module)

  for {id, module} <- @messages do
    def id(unquote(module)), do: unquote(id)
  end

  @doc """
  Encodes a message struct to raw bytes.

  Raises `ArgumentError` if a field does not fit the protocol, e.g. a name
  that is too long or a speed above 100.
  """
  @spec encode(t()) :: binary()
  def encode(message), do: IO.iodata_to_binary([id(message) | encode_fields(message)])

  defp encode_fields(%HubProperty{property: property, operation: operation, value: value}) do
    name = Enums.to_name(:hub_property, Enums.to_value(:hub_property, property))

    operation =
      Enums.to_name(:hub_property_operation, Enums.to_value(:hub_property_operation, operation))

    payload = if operation in [:set, :update], do: encode_property(name, value), else: []

    [
      enum(:hub_property, property, :property),
      enum(:hub_property_operation, operation, :operation),
      payload
    ]
  end

  defp encode_fields(%HubAction{action: action}), do: [enum(:hub_action, action, :action)]

  defp encode_fields(%HubAlert{alert: alert, operation: operation, status: status}) do
    status =
      if Enums.to_value(:hub_alert_operation, operation) == 0x04,
        do: enum(:alert_status, status, :status),
        else: []

    [enum(:hub_alert, alert, :alert), enum(:hub_alert_operation, operation, :operation), status]
  end

  defp encode_fields(%HubAttachedIO{port: port, event: event} = m) do
    fields =
      case Enums.to_name(:io_event, Enums.to_value(:io_event, event)) do
        :detached ->
          []

        :attached ->
          [
            enum16(:io_type, m.io_type, :io_type),
            u32(Version.encode(m.hardware_revision), :hardware_revision),
            u32(Version.encode(m.software_revision), :software_revision)
          ]

        :attached_virtual ->
          [enum16(:io_type, m.io_type, :io_type), u8(m.port_a, :port_a), u8(m.port_b, :port_b)]

        other ->
          raise ArgumentError, "unknown io_event: #{inspect(other)}"
      end

    [u8(port, :port), enum(:io_event, event, :event) | fields]
  end

  defp encode_fields(%GenericError{command_type: command_type, error_code: error_code}) do
    [
      enum(:message_type, command_type, :command_type),
      enum(:error_code, error_code, :error_code)
    ]
  end

  defp encode_fields(%HwNetworkCommand{command: command} = m) do
    fields =
      case Enums.to_name(:hw_network_command, Enums.to_value(:hw_network_command, command)) do
        :connection_request ->
          [enum(:button_state, m.button, :button)]

        command when command in [:family_set, :family] ->
          [u8(m.family, :family)]

        command when command in [:subfamily_set, :subfamily] ->
          [u8(m.subfamily, :subfamily)]

        command when command in [:extended_family_set, :extended_family] ->
          unless m.family in 0..0xF, do: raise(ArgumentError, "family must be 0..15")
          unless m.subfamily in 0..0x7, do: raise(ArgumentError, "subfamily must be 0..7")
          [<<0::1, m.subfamily::3, m.family::4>>]

        command when is_atom(command) ->
          []

        command ->
          raise ArgumentError, "unknown hw_network_command: #{inspect(command)}"
      end

    [enum(:hw_network_command, command, :command) | fields]
  end

  defp encode_fields(%GoIntoBootMode{}), do: [@boot_safety_string]
  defp encode_fields(%LockMemory{}), do: [@lock_safety_string]
  defp encode_fields(%LockStatusRequest{}), do: []
  defp encode_fields(%LockStatus{status: status}), do: [enum(:lock_status, status, :status)]

  defp encode_fields(%PortInformationRequest{port: port, information_type: type}),
    do: [u8(port, :port), enum(:port_information_type, type, :information_type)]

  defp encode_fields(%PortModeInformationRequest{port: port, mode: mode, information_type: type}),
    do: [u8(port, :port), u8(mode, :mode), enum(:mode_information_type, type, :information_type)]

  defp encode_fields(%PortInputFormatSetupSingle{} = m), do: input_format(m)

  defp encode_fields(%PortInputFormatSetupCombined{port: port, sub_command: sub_command} = m) do
    fields =
      if Enums.to_value(:combined_sub_command, sub_command) == 0x01 do
        [u8(m.combination_index, :combination_index) | Enum.map(m.mode_datasets, &mode_dataset/1)]
      else
        []
      end

    [u8(port, :port), enum(:combined_sub_command, sub_command, :sub_command) | fields]
  end

  defp encode_fields(%PortInformation{port: port, information_type: type} = m) do
    fields =
      case Enums.to_name(:port_information_type, Enums.to_value(:port_information_type, type)) do
        :mode_info ->
          [
            flags(:port_capabilities, m.capabilities, :capabilities),
            u8(m.total_mode_count, :total_mode_count),
            positions(m.input_modes, :input_modes),
            positions(m.output_modes, :output_modes)
          ]

        :possible_mode_combinations ->
          Enum.map(m.mode_combinations, &positions(&1, :mode_combinations))

        other ->
          raise ArgumentError, "unsupported information_type: #{inspect(other)}"
      end

    [u8(port, :port), enum(:port_information_type, type, :information_type) | fields]
  end

  defp encode_fields(%PortModeInformation{port: port, mode: mode, information_type: type} = m) do
    name =
      Enums.to_name(:mode_information_type, Enums.to_value(:mode_information_type, type))

    [
      u8(port, :port),
      u8(mode, :mode),
      enum(:mode_information_type, type, :information_type),
      encode_mode_information(name, m.value)
    ]
  end

  defp encode_fields(%PortValueSingle{port: port, value: value}),
    do: [u8(port, :port), binary(value, :value)]

  defp encode_fields(%PortValueCombined{port: port, mode_datasets: mode_datasets, value: value}),
    do: [u8(port, :port), positions(mode_datasets, :mode_datasets), binary(value, :value)]

  defp encode_fields(%PortInputFormatSingle{} = m), do: input_format(m)

  defp encode_fields(%PortInputFormatCombined{port: port} = m) do
    unless m.combination_index in 0..0xF,
      do:
        raise(
          ArgumentError,
          "combination_index must be 0..15, got: #{inspect(m.combination_index)}"
        )

    multi_update = if bool(m.multi_update, :multi_update) == <<1>>, do: 1, else: 0

    [
      u8(port, :port),
      <<multi_update::1, 0::3, m.combination_index::4>>,
      positions(m.mode_datasets, :mode_datasets)
    ]
  end

  defp encode_fields(%VirtualPortSetup{sub_command: sub_command} = m) do
    case Enums.to_name(
           :virtual_port_sub_command,
           Enums.to_value(:virtual_port_sub_command, sub_command)
         ) do
      :disconnect -> [0x00, u8(m.port, :port)]
      :connect -> [0x01, u8(m.port_a, :port_a), u8(m.port_b, :port_b)]
      other -> raise ArgumentError, "unknown sub_command: #{inspect(other)}"
    end
  end

  defp encode_fields(%PortOutputCommand{port: port, command: command} = m) do
    startup = Enums.to_value(:startup, m.startup)
    completion = Enums.to_value(:completion, m.completion)

    unless startup in 0..0xF and completion in 0..0xF,
      do: raise(ArgumentError, "startup and completion must be 0..15")

    [u8(port, :port), <<startup::4, completion::4>>, Output.encode(command)]
  end

  defp encode_fields(%PortOutputCommandFeedback{feedback: [_ | _] = feedback}) do
    for {port, flags} <- feedback, do: [u8(port, :port), flags(:feedback, flags, :feedback)]
  end

  defp encode_fields(%PortOutputCommandFeedback{feedback: feedback}),
    do: raise(ArgumentError, "feedback must list at least one port, got: #{inspect(feedback)}")

  defp input_format(m) do
    [
      u8(m.port, :port),
      u8(m.mode, :mode),
      u32(m.delta_interval, :delta_interval),
      bool(m.notification_enabled, :notification_enabled)
    ]
  end

  defp mode_dataset({mode, dataset}) when mode in 0..0xF and dataset in 0..0xF,
    do: <<mode::4, dataset::4>>

  defp mode_dataset(other),
    do:
      raise(ArgumentError, "mode_datasets must be {0..15, 0..15} tuples, got: #{inspect(other)}")

  defp encode_property(:advertising_name, value), do: string(value, 14, :value)
  defp encode_property(name, value) when name in @string_properties, do: binary(value, :value)
  defp encode_property(:button, value), do: enum(:button_state, value, :value)

  defp encode_property(name, value) when name in [:fw_version, :hw_version],
    do: u32(Version.encode(value), :value)

  defp encode_property(:rssi, value), do: s8(value, :value)
  defp encode_property(:battery_voltage, value), do: u8(value, :value)
  defp encode_property(:battery_type, value), do: enum(:battery_type, value, :value)
  defp encode_property(:lwp_version, value), do: u16(Version.encode_lwp(value), :value)
  defp encode_property(:system_type_id, value), do: enum(:system_type, value, :value)
  defp encode_property(:hw_network_id, value), do: u8(value, :value)
  defp encode_property(:hw_network_family, value), do: u8(value, :value)

  defp encode_property(name, value) when name in [:primary_mac_address, :secondary_mac_address],
    do: binary(value, 6, :value)

  defp encode_property(_unknown, value), do: binary(value, :value)

  defp encode_mode_information(:name, value), do: string(value, 11, :value)
  defp encode_mode_information(:symbol, value), do: string(value, 5, :value)

  defp encode_mode_information(type, {min, max}) when type in [:raw, :pct, :si],
    do: [float32(min, :min), float32(max, :max)]

  defp encode_mode_information(:mapping, %{input: input, output: output}),
    do: [flags(:mapping, input, :input), flags(:mapping, output, :output)]

  defp encode_mode_information(:motor_bias, value), do: u8(value, :value)
  defp encode_mode_information(:capability_bits, value), do: binary(value, 6, :value)

  defp encode_mode_information(:value_format, %ValueFormat{} = value),
    do: ValueFormat.to_bytes(value)

  defp encode_mode_information(type, value)
       when type in [:raw, :pct, :si, :mapping, :value_format],
       do: raise(ArgumentError, "invalid #{type} value: #{inspect(value)}")

  defp encode_mode_information(_other, value), do: binary(value, :value)

  @doc """
  Decodes raw bytes into a message struct.

      iex> ExLWP.Message.decode(<<0x02, 0x30>>)
      {:ok, %ExLWP.Message.HubAction{action: :hub_will_switch_off}}

      iex> ExLWP.Message.decode(<<0xEE>>)
      {:error, {:unknown_message, 0xEE}}

      iex> ExLWP.Message.decode(<<0x21, 0x00>>)
      {:error, {:malformed, ExLWP.Message.PortInformationRequest}}
  """
  @spec decode(binary()) :: {:ok, t()} | {:error, decode_error()}
  def decode(<<>>), do: {:error, :empty}

  def decode(<<id, body::binary>>) do
    case @messages do
      %{^id => module} ->
        case decode(module, body) do
          {:ok, message} -> {:ok, message}
          _error -> {:error, {:malformed, module}}
        end

      _ ->
        {:error, {:unknown_message, id}}
    end
  end

  defp decode(HubProperty, <<property, operation, payload::binary>>) do
    property = Enums.to_name(:hub_property, property)
    operation = Enums.to_name(:hub_property_operation, operation)

    value_result =
      cond do
        operation in [:set, :update] -> decode_property(property, payload)
        payload == <<>> -> {:ok, nil}
        true -> :error
      end

    with {:ok, value} <- value_result do
      {:ok, %HubProperty{property: property, operation: operation, value: value}}
    end
  end

  defp decode(HubAction, <<action>>),
    do: {:ok, %HubAction{action: Enums.to_name(:hub_action, action)}}

  defp decode(HubAlert, <<alert, 0x04, status>>) do
    {:ok,
     %HubAlert{
       alert: Enums.to_name(:hub_alert, alert),
       operation: :update,
       status: Enums.to_name(:alert_status, status)
     }}
  end

  defp decode(HubAlert, <<alert, operation>>) when operation != 0x04 do
    {:ok,
     %HubAlert{
       alert: Enums.to_name(:hub_alert, alert),
       operation: Enums.to_name(:hub_alert_operation, operation)
     }}
  end

  defp decode(HubAttachedIO, <<port, 0x00>>),
    do: {:ok, %HubAttachedIO{port: port, event: :detached}}

  defp decode(HubAttachedIO, <<port, 0x01, type::little-16, hw::little-32, sw::little-32>>) do
    {:ok,
     %HubAttachedIO{
       port: port,
       event: :attached,
       io_type: Enums.to_name(:io_type, type),
       hardware_revision: Version.decode(hw),
       software_revision: Version.decode(sw)
     }}
  end

  defp decode(HubAttachedIO, <<port, 0x02, type::little-16, port_a, port_b>>) do
    {:ok,
     %HubAttachedIO{
       port: port,
       event: :attached_virtual,
       io_type: Enums.to_name(:io_type, type),
       port_a: port_a,
       port_b: port_b
     }}
  end

  defp decode(GenericError, <<command_type, error_code>>) do
    {:ok,
     %GenericError{
       command_type: Enums.to_name(:message_type, command_type),
       error_code: Enums.to_name(:error_code, error_code)
     }}
  end

  defp decode(HwNetworkCommand, <<command, payload::binary>>) do
    case {Enums.to_name(:hw_network_command, command), payload} do
      {:connection_request, <<button>>} ->
        {:ok,
         %HwNetworkCommand{
           command: :connection_request,
           button: Enums.to_name(:button_state, button)
         }}

      {command, <<family>>} when command in [:family_set, :family] ->
        {:ok, %HwNetworkCommand{command: command, family: family}}

      {command, <<subfamily>>} when command in [:subfamily_set, :subfamily] ->
        {:ok, %HwNetworkCommand{command: command, subfamily: subfamily}}

      {command, <<0::1, subfamily::3, family::4>>}
      when command in [:extended_family_set, :extended_family] ->
        {:ok, %HwNetworkCommand{command: command, family: family, subfamily: subfamily}}

      {command, <<>>}
      when command in [
             :family_request,
             :join_denied,
             :get_family,
             :get_subfamily,
             :get_extended_family,
             :reset_long_press_timing
           ] ->
        {:ok, %HwNetworkCommand{command: command}}

      _ ->
        :error
    end
  end

  defp decode(GoIntoBootMode, @boot_safety_string), do: {:ok, %GoIntoBootMode{}}
  defp decode(LockMemory, @lock_safety_string), do: {:ok, %LockMemory{}}
  defp decode(LockStatusRequest, <<>>), do: {:ok, %LockStatusRequest{}}

  defp decode(LockStatus, <<status>>),
    do: {:ok, %LockStatus{status: Enums.to_name(:lock_status, status)}}

  defp decode(PortInformationRequest, <<port, type>>) do
    {:ok,
     %PortInformationRequest{
       port: port,
       information_type: Enums.to_name(:port_information_type, type)
     }}
  end

  defp decode(PortModeInformationRequest, <<port, mode, type>>) do
    {:ok,
     %PortModeInformationRequest{
       port: port,
       mode: mode,
       information_type: Enums.to_name(:mode_information_type, type)
     }}
  end

  defp decode(PortInputFormatSetupSingle, body),
    do: decode_input_format(%PortInputFormatSetupSingle{}, body)

  defp decode(PortInputFormatSetupCombined, <<port, 0x01, index, mode_datasets::binary>>) do
    {:ok,
     %PortInputFormatSetupCombined{
       port: port,
       sub_command: :set_mode_dataset_combinations,
       combination_index: index,
       mode_datasets: for(<<mode::4, dataset::4 <- mode_datasets>>, do: {mode, dataset})
     }}
  end

  defp decode(PortInputFormatSetupCombined, <<port, sub_command>>) when sub_command != 0x01 do
    {:ok,
     %PortInputFormatSetupCombined{
       port: port,
       sub_command: Enums.to_name(:combined_sub_command, sub_command)
     }}
  end

  defp decode(
         PortInformation,
         <<port, 0x01, capabilities, total, input::little-16, output::little-16>>
       ) do
    {:ok,
     %PortInformation{
       port: port,
       information_type: :mode_info,
       capabilities: Enums.to_flags(:port_capabilities, capabilities),
       total_mode_count: total,
       input_modes: to_positions(input),
       output_modes: to_positions(output)
     }}
  end

  defp decode(PortInformation, <<port, 0x02, combinations::binary>>)
       when rem(byte_size(combinations), 2) == 0 do
    {:ok,
     %PortInformation{
       port: port,
       information_type: :possible_mode_combinations,
       mode_combinations: for(<<mask::little-16 <- combinations>>, do: to_positions(mask))
     }}
  end

  defp decode(PortModeInformation, <<port, mode, type, payload::binary>>) do
    type = Enums.to_name(:mode_information_type, type)

    with {:ok, value} <- decode_mode_information(type, payload) do
      {:ok, %PortModeInformation{port: port, mode: mode, information_type: type, value: value}}
    end
  end

  defp decode(PortValueSingle, <<port, value::binary>>),
    do: {:ok, %PortValueSingle{port: port, value: value}}

  defp decode(PortValueCombined, <<port, mode_datasets::little-16, value::binary>>) do
    {:ok,
     %PortValueCombined{port: port, mode_datasets: to_positions(mode_datasets), value: value}}
  end

  defp decode(PortInputFormatSingle, body),
    do: decode_input_format(%PortInputFormatSingle{}, body)

  defp decode(
         PortInputFormatCombined,
         <<port, multi_update::1, 0::3, index::4, mode_datasets::little-16>>
       ) do
    {:ok,
     %PortInputFormatCombined{
       port: port,
       combination_index: index,
       multi_update: multi_update == 1,
       mode_datasets: to_positions(mode_datasets)
     }}
  end

  defp decode(VirtualPortSetup, <<0x00, port>>),
    do: {:ok, %VirtualPortSetup{sub_command: :disconnect, port: port}}

  defp decode(VirtualPortSetup, <<0x01, port_a, port_b>>),
    do: {:ok, %VirtualPortSetup{sub_command: :connect, port_a: port_a, port_b: port_b}}

  defp decode(PortOutputCommand, <<port, startup::4, completion::4, command::binary>>) do
    with {:ok, command} <- Output.decode(command) do
      {:ok,
       %PortOutputCommand{
         port: port,
         startup: Enums.to_name(:startup, startup),
         completion: Enums.to_name(:completion, completion),
         command: command
       }}
    end
  end

  defp decode(PortOutputCommandFeedback, <<_, _, _::binary>> = body)
       when rem(byte_size(body), 2) == 0 do
    feedback = for <<port, flags <- body>>, do: {port, Enums.to_flags(:feedback, flags)}
    {:ok, %PortOutputCommandFeedback{feedback: feedback}}
  end

  defp decode(_module, _body), do: :error

  defp decode_input_format(struct, <<port, mode, delta::little-32, notification>>) do
    with {:ok, enabled} <- from_bool(notification) do
      {:ok,
       %{struct | port: port, mode: mode, delta_interval: delta, notification_enabled: enabled}}
    end
  end

  defp decode_input_format(_struct, _body), do: :error

  defp decode_property(name, payload) when name in @string_properties,
    do: {:ok, from_string(payload)}

  defp decode_property(:button, <<button>>), do: {:ok, Enums.to_name(:button_state, button)}

  defp decode_property(name, <<version::little-32>>) when name in [:fw_version, :hw_version],
    do: {:ok, Version.decode(version)}

  defp decode_property(:rssi, <<rssi::signed>>), do: {:ok, rssi}
  defp decode_property(:battery_voltage, <<percent>>), do: {:ok, percent}
  defp decode_property(:battery_type, <<type>>), do: {:ok, Enums.to_name(:battery_type, type)}

  defp decode_property(:lwp_version, <<version::little-16>>),
    do: {:ok, Version.decode_lwp(version)}

  defp decode_property(:system_type_id, <<type>>),
    do: {:ok, Enums.to_name(:system_type, type)}

  defp decode_property(:hw_network_id, <<id>>), do: {:ok, id}
  defp decode_property(:hw_network_family, <<family>>), do: {:ok, family}

  defp decode_property(name, <<mac::binary-size(6)>>)
       when name in [:primary_mac_address, :secondary_mac_address],
       do: {:ok, mac}

  defp decode_property(name, payload) when is_integer(name), do: {:ok, payload}
  defp decode_property(_name, _payload), do: :error

  defp decode_mode_information(type, payload) when type in [:name, :symbol],
    do: {:ok, from_string(payload)}

  defp decode_mode_information(type, <<min::float-little-32, max::float-little-32>>)
       when type in [:raw, :pct, :si],
       do: {:ok, {min, max}}

  defp decode_mode_information(:mapping, <<input, output>>) do
    {:ok, %{input: Enums.to_flags(:mapping, input), output: Enums.to_flags(:mapping, output)}}
  end

  defp decode_mode_information(:motor_bias, <<bias>>), do: {:ok, bias}
  defp decode_mode_information(:capability_bits, <<bits::binary-size(6)>>), do: {:ok, bits}

  defp decode_mode_information(:value_format, <<_::binary-size(4)>> = format),
    do: {:ok, ValueFormat.from_bytes(format)}

  defp decode_mode_information(type, _payload)
       when type in [:raw, :pct, :si, :mapping, :motor_bias, :capability_bits, :value_format],
       do: :error

  defp decode_mode_information(_other, payload), do: {:ok, payload}
end
