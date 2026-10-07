defmodule ExLWP.MessageTest do
  use ExUnit.Case, async: true

  @moduletag spec: "ARCH-5"

  import Bitwise

  alias ExLWP.{Message, Output, ValueFormat, Version}

  @mac <<0x90, 0x84, 0x2B, 0x01, 0x02, 0x03>>

  # Every message in the protocol, with its variants, paired with its raw
  # bytes and the requirement it covers.
  @examples [
    # Hub Properties
    {"MSG-1", "a request for the advertising name",
     %Message.HubProperty{property: :advertising_name, operation: :request_update},
     <<0x01, 0x01, 0x05>>},
    {"MSG-1", "an advertising name update",
     %Message.HubProperty{property: :advertising_name, operation: :update, value: "Technic Hub"},
     <<0x01, 0x01, 0x06, "Technic Hub">>},
    {"MSG-1", "a new advertising name",
     %Message.HubProperty{property: :advertising_name, operation: :set, value: "Brick"},
     <<0x01, 0x01, 0x01, "Brick">>},
    {"MSG-1", "a reset of the advertising name",
     %Message.HubProperty{property: :advertising_name, operation: :reset}, <<0x01, 0x01, 0x04>>},
    {"MSG-1", "a button update",
     %Message.HubProperty{property: :button, operation: :update, value: :pressed},
     <<0x01, 0x02, 0x06, 0x01>>},
    {"MSG-1", "a firmware version update",
     %Message.HubProperty{
       property: :fw_version,
       operation: :update,
       value: %Version{major: 1, minor: 7, bugfix: 37, build: 1510}
     }, <<0x01, 0x03, 0x06, 0x10, 0x15, 0x37, 0x17>>},
    {"MSG-1", "a hardware version update",
     %Message.HubProperty{
       property: :hw_version,
       operation: :update,
       value: %Version{major: 0, minor: 0, bugfix: 0, build: 1}
     }, <<0x01, 0x04, 0x06, 0x01, 0x00, 0x00, 0x00>>},
    {"MSG-1", "an RSSI update",
     %Message.HubProperty{property: :rssi, operation: :update, value: -60},
     <<0x01, 0x05, 0x06, 0xC4>>},
    {"MSG-1", "a request to enable battery voltage updates",
     %Message.HubProperty{property: :battery_voltage, operation: :enable_updates},
     <<0x01, 0x06, 0x02>>},
    {"MSG-1", "a request to disable RSSI updates",
     %Message.HubProperty{property: :rssi, operation: :disable_updates}, <<0x01, 0x05, 0x03>>},
    {"MSG-1", "a battery voltage update",
     %Message.HubProperty{property: :battery_voltage, operation: :update, value: 87},
     <<0x01, 0x06, 0x06, 87>>},
    {"MSG-1", "a battery type update",
     %Message.HubProperty{property: :battery_type, operation: :update, value: :rechargeable},
     <<0x01, 0x07, 0x06, 0x01>>},
    {"MSG-1", "a manufacturer name update",
     %Message.HubProperty{
       property: :manufacturer_name,
       operation: :update,
       value: "LEGO System A/S"
     }, <<0x01, 0x08, 0x06, "LEGO System A/S">>},
    {"MSG-1", "a radio firmware version update",
     %Message.HubProperty{property: :radio_firmware_version, operation: :update, value: "7.1e"},
     <<0x01, 0x09, 0x06, "7.1e">>},
    {"MSG-1", "an LWP version update",
     %Message.HubProperty{
       property: :lwp_version,
       operation: :update,
       value: %Version{major: 3, minor: 0}
     }, <<0x01, 0x0A, 0x06, 0x00, 0x03>>},
    {"MSG-1", "a system type update",
     %Message.HubProperty{property: :system_type_id, operation: :update, value: :boost_hub},
     <<0x01, 0x0B, 0x06, 0x40>>},
    {"MSG-1", "a H/W network ID update",
     %Message.HubProperty{property: :hw_network_id, operation: :update, value: 5},
     <<0x01, 0x0C, 0x06, 0x05>>},
    {"MSG-1", "a primary MAC address update",
     %Message.HubProperty{property: :primary_mac_address, operation: :update, value: @mac},
     <<0x01, 0x0D, 0x06, @mac::binary>>},
    {"MSG-1", "a secondary MAC address update",
     %Message.HubProperty{property: :secondary_mac_address, operation: :update, value: @mac},
     <<0x01, 0x0E, 0x06, @mac::binary>>},
    {"MSG-1", "a H/W network family update",
     %Message.HubProperty{property: :hw_network_family, operation: :update, value: 3},
     <<0x01, 0x0F, 0x06, 0x03>>},

    # Hub Actions
    {"MSG-2", "a switch off action", %Message.HubAction{action: :switch_off_hub}, <<0x02, 0x01>>},
    {"MSG-2", "a will disconnect action", %Message.HubAction{action: :hub_will_disconnect},
     <<0x02, 0x31>>},

    # Hub Alerts
    {"MSG-3", "a request to enable low voltage alerts",
     %Message.HubAlert{alert: :low_voltage, operation: :enable_updates}, <<0x03, 0x01, 0x01>>},
    {"MSG-3", "a request for the over power alert",
     %Message.HubAlert{alert: :over_power_condition, operation: :request_updates},
     <<0x03, 0x04, 0x03>>},
    {"MSG-3", "a high current alert update",
     %Message.HubAlert{alert: :high_current, operation: :update, status: :alert},
     <<0x03, 0x02, 0x04, 0xFF>>},

    # Hub Attached I/O
    {"MSG-4", "a detached I/O", %Message.HubAttachedIO{port: 1, event: :detached},
     <<0x04, 0x01, 0x00>>},
    {"MSG-4", "an attached I/O",
     %Message.HubAttachedIO{
       port: 0,
       event: :attached,
       io_type: :internal_motor_with_tacho,
       hardware_revision: %Version{major: 1, minor: 0, bugfix: 0, build: 0},
       software_revision: %Version{major: 1, minor: 0, bugfix: 0, build: 0}
     }, <<0x04, 0x00, 0x01, 0x27, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x10>>},
    {"MSG-4", "an attached virtual I/O",
     %Message.HubAttachedIO{
       port: 0x10,
       event: :attached_virtual,
       io_type: :internal_motor_with_tacho,
       port_a: 0,
       port_b: 1
     }, <<0x04, 0x10, 0x02, 0x27, 0x00, 0x00, 0x01>>},

    # Generic Error Messages
    {"MSG-5", "an invalid use error",
     %Message.GenericError{command_type: :port_output_command, error_code: :invalid_use},
     <<0x05, 0x81, 0x06>>},

    # H/W NetWork Commands
    {"MSG-6", "a connection request",
     %Message.HwNetworkCommand{command: :connection_request, button: :pressed},
     <<0x08, 0x02, 0x01>>},
    {"MSG-6", "a family request", %Message.HwNetworkCommand{command: :family_request},
     <<0x08, 0x03>>},
    {"MSG-6", "a family set", %Message.HwNetworkCommand{command: :family_set, family: 4},
     <<0x08, 0x04, 0x04>>},
    {"MSG-6", "a join denied", %Message.HwNetworkCommand{command: :join_denied}, <<0x08, 0x05>>},
    {"MSG-6", "a get family", %Message.HwNetworkCommand{command: :get_family}, <<0x08, 0x06>>},
    {"MSG-6", "a family", %Message.HwNetworkCommand{command: :family, family: 2},
     <<0x08, 0x07, 0x02>>},
    {"MSG-6", "a get subfamily", %Message.HwNetworkCommand{command: :get_subfamily},
     <<0x08, 0x08>>},
    {"MSG-6", "a subfamily", %Message.HwNetworkCommand{command: :subfamily, subfamily: 3},
     <<0x08, 0x09, 0x03>>},
    {"MSG-6", "a subfamily set", %Message.HwNetworkCommand{command: :subfamily_set, subfamily: 7},
     <<0x08, 0x0A, 0x07>>},
    {"MSG-6", "a get extended family", %Message.HwNetworkCommand{command: :get_extended_family},
     <<0x08, 0x0B>>},
    {"MSG-6", "an extended family",
     %Message.HwNetworkCommand{command: :extended_family, family: 5, subfamily: 3},
     <<0x08, 0x0C, 0b0_011_0101>>},
    {"MSG-6", "an extended family set",
     %Message.HwNetworkCommand{command: :extended_family_set, family: 8, subfamily: 7},
     <<0x08, 0x0D, 0b0_111_1000>>},
    {"MSG-6", "a reset long press timing",
     %Message.HwNetworkCommand{command: :reset_long_press_timing}, <<0x08, 0x0E>>},

    # F/W update
    {"MSG-7", "a go into boot mode", %Message.GoIntoBootMode{}, <<0x10, "LPF2-Boot">>},
    {"MSG-7", "a lock memory", %Message.LockMemory{}, <<0x11, "Lock-Mem">>},
    {"MSG-7", "a lock status request", %Message.LockStatusRequest{}, <<0x12>>},
    {"MSG-7", "a lock status", %Message.LockStatus{status: :not_locked}, <<0x13, 0xFF>>},

    # Port information
    {"MSG-8", "a port information request",
     %Message.PortInformationRequest{port: 1, information_type: :mode_info},
     <<0x21, 0x01, 0x01>>},
    {"MSG-8", "a port mode information request",
     %Message.PortModeInformationRequest{port: 1, mode: 2, information_type: :value_format},
     <<0x22, 0x01, 0x02, 0x80>>},
    {"MSG-8", "a port's mode info",
     %Message.PortInformation{
       port: 0,
       information_type: :mode_info,
       capabilities: [:output, :input, :logical_combinable, :logical_synchronizable],
       total_mode_count: 6,
       input_modes: [1, 2, 3, 4],
       output_modes: [0]
     }, <<0x43, 0x00, 0x01, 0x0F, 0x06, 0x1E, 0x00, 0x01, 0x00>>},
    {"MSG-8", "a port's possible mode combinations",
     %Message.PortInformation{
       port: 0,
       information_type: :possible_mode_combinations,
       mode_combinations: [[1, 2, 4], [0, 1], [0, 3]]
     }, <<0x43, 0x00, 0x02, 0x16, 0x00, 0x03, 0x00, 0x09, 0x00>>},
    {"MSG-8", "a mode's name",
     %Message.PortModeInformation{port: 0, mode: 0, information_type: :name, value: "POWER"},
     <<0x44, 0x00, 0x00, 0x00, "POWER">>},
    {"MSG-8", "a mode's raw range",
     %Message.PortModeInformation{
       port: 0,
       mode: 0,
       information_type: :raw,
       value: {-100.0, 100.0}
     }, <<0x44, 0x00, 0x00, 0x01, -100.0::float-little-32, 100.0::float-little-32>>},
    {"MSG-8", "a mode's percent range",
     %Message.PortModeInformation{port: 0, mode: 0, information_type: :pct, value: {0.0, 100.0}},
     <<0x44, 0x00, 0x00, 0x02, 0.0::float-little-32, 100.0::float-little-32>>},
    {"MSG-8", "a mode's SI range",
     %Message.PortModeInformation{port: 0, mode: 0, information_type: :si, value: {0.0, 360.0}},
     <<0x44, 0x00, 0x00, 0x03, 0.0::float-little-32, 360.0::float-little-32>>},
    {"MSG-8", "a mode's symbol",
     %Message.PortModeInformation{port: 0, mode: 2, information_type: :symbol, value: "DEG"},
     <<0x44, 0x00, 0x02, 0x04, "DEG">>},
    {"MSG-8", "a mode's mapping",
     %Message.PortModeInformation{
       port: 0,
       mode: 0,
       information_type: :mapping,
       value: %{input: [], output: [:absolute, :supports_null]}
     }, <<0x44, 0x00, 0x00, 0x05, 0x00, 0x90>>},
    {"MSG-8", "a mode's internal information",
     %Message.PortModeInformation{port: 0, mode: 0, information_type: :internal, value: <<0xAA>>},
     <<0x44, 0x00, 0x00, 0x06, 0xAA>>},
    {"MSG-8", "a mode's motor bias",
     %Message.PortModeInformation{port: 0, mode: 0, information_type: :motor_bias, value: 20},
     <<0x44, 0x00, 0x00, 0x07, 20>>},
    {"MSG-8", "a mode's capability bits",
     %Message.PortModeInformation{
       port: 0,
       mode: 0,
       information_type: :capability_bits,
       value: <<1, 2, 3, 4, 5, 6>>
     }, <<0x44, 0x00, 0x00, 0x08, 1, 2, 3, 4, 5, 6>>},
    {"MSG-8", "a mode's value format",
     %Message.PortModeInformation{
       port: 0,
       mode: 2,
       information_type: :value_format,
       value: %ValueFormat{datasets: 1, type: :int32, figures: 4, decimals: 0}
     }, <<0x44, 0x00, 0x02, 0x80, 1, 2, 4, 0>>},

    # Port input format
    {"MSG-9", "a single mode input format setup",
     %Message.PortInputFormatSetupSingle{
       port: 1,
       mode: 2,
       delta_interval: 5,
       notification_enabled: true
     }, <<0x41, 0x01, 0x02, 0x05, 0x00, 0x00, 0x00, 0x01>>},
    {"MSG-9", "a combined mode setup of mode/datasets",
     %Message.PortInputFormatSetupCombined{
       port: 1,
       sub_command: :set_mode_dataset_combinations,
       combination_index: 0,
       mode_datasets: [{1, 0}, {2, 0}]
     }, <<0x42, 0x01, 0x01, 0x00, 0x10, 0x20>>},
    {"MSG-9", "a combined mode lock",
     %Message.PortInputFormatSetupCombined{port: 1, sub_command: :lock}, <<0x42, 0x01, 0x02>>},
    {"MSG-9", "a combined mode unlock with multi update",
     %Message.PortInputFormatSetupCombined{
       port: 1,
       sub_command: :unlock_and_start_with_multi_update
     }, <<0x42, 0x01, 0x03>>},
    {"MSG-9", "a combined mode unlock without multi update",
     %Message.PortInputFormatSetupCombined{
       port: 1,
       sub_command: :unlock_and_start_without_multi_update
     }, <<0x42, 0x01, 0x04>>},
    {"MSG-9", "a combined mode reset",
     %Message.PortInputFormatSetupCombined{port: 1, sub_command: :reset}, <<0x42, 0x01, 0x06>>},
    {"MSG-9", "a single mode input format",
     %Message.PortInputFormatSingle{
       port: 1,
       mode: 2,
       delta_interval: 5,
       notification_enabled: false
     }, <<0x47, 0x01, 0x02, 0x05, 0x00, 0x00, 0x00, 0x00>>},
    {"MSG-9", "a combined mode input format",
     %Message.PortInputFormatCombined{
       port: 1,
       combination_index: 2,
       multi_update: true,
       mode_datasets: [0, 1, 2, 3, 4]
     }, <<0x48, 0x01, 0x82, 0x1F, 0x00>>},

    # Port values
    {"MSG-10", "a single mode port value",
     %Message.PortValueSingle{port: 1, value: <<0x68, 0x01, 0x00, 0x00>>},
     <<0x45, 0x01, 0x68, 0x01, 0x00, 0x00>>},
    {"MSG-10", "a combined mode port value",
     %Message.PortValueCombined{port: 1, mode_datasets: [2, 4], value: <<0x05, 0x06>>},
     <<0x46, 0x01, 0x14, 0x00, 0x05, 0x06>>},

    # Virtual Port Setup
    {"MSG-12", "a virtual port connect",
     %Message.VirtualPortSetup{sub_command: :connect, port_a: 0, port_b: 1},
     <<0x61, 0x01, 0x00, 0x01>>},
    {"MSG-12", "a virtual port disconnect",
     %Message.VirtualPortSetup{sub_command: :disconnect, port: 0x10}, <<0x61, 0x00, 0x10>>},

    # Port Output Commands, one per sub command
    {"MSG-13", "a StartPower(Power1, Power2)",
     %Message.PortOutputCommand{
       port: 0x10,
       command: %Output.StartPowerSynced{power1: 50, power2: -50}
     }, <<0x81, 0x10, 0x11, 0x02, 50, 0xCE>>},
    {"MSG-13", "a SetAccTime",
     %Message.PortOutputCommand{port: 0, command: %Output.SetAccTime{time: 1000, profile: 0}},
     <<0x81, 0x00, 0x11, 0x05, 0xE8, 0x03, 0x00>>},
    {"MSG-13", "a SetDecTime",
     %Message.PortOutputCommand{port: 0, command: %Output.SetDecTime{time: 500, profile: 1}},
     <<0x81, 0x00, 0x11, 0x06, 0xF4, 0x01, 0x01>>},
    {"MSG-13", "a StartSpeed",
     %Message.PortOutputCommand{port: 0, command: %Output.StartSpeed{speed: 50}},
     <<0x81, 0x00, 0x11, 0x07, 50, 100, 0x00>>},
    {"MSG-13", "a StartSpeed(Speed1, Speed2)",
     %Message.PortOutputCommand{
       port: 0x10,
       command: %Output.StartSpeedSynced{
         speed1: 50,
         speed2: -50,
         max_power: 80,
         use_profile: [:acceleration, :deceleration]
       }
     }, <<0x81, 0x10, 0x11, 0x08, 50, 0xCE, 80, 0x03>>},
    {"MSG-13", "a StartSpeedForTime",
     %Message.PortOutputCommand{
       port: 0,
       command: %Output.StartSpeedForTime{time: 2000, speed: 75, end_state: :hold}
     }, <<0x81, 0x00, 0x11, 0x09, 0xD0, 0x07, 75, 100, 126, 0x00>>},
    {"MSG-13", "a StartSpeedForTime(Time, SpeedL, SpeedR)",
     %Message.PortOutputCommand{
       port: 0x10,
       command: %Output.StartSpeedForTimeSynced{
         time: 1000,
         speed_l: 50,
         speed_r: 30,
         end_state: :float,
         use_profile: [:acceleration]
       }
     }, <<0x81, 0x10, 0x11, 0x0A, 0xE8, 0x03, 50, 30, 100, 0, 0x01>>},
    {"MSG-13", "a StartSpeedForDegrees",
     %Message.PortOutputCommand{
       port: 0,
       command: %Output.StartSpeedForDegrees{degrees: 360, speed: -50}
     }, <<0x81, 0x00, 0x11, 0x0B, 0x68, 0x01, 0x00, 0x00, 0xCE, 100, 127, 0x00>>},
    {"MSG-13", "a StartSpeedForDegrees(Degrees, SpeedL, SpeedR)",
     %Message.PortOutputCommand{
       port: 0x10,
       command: %Output.StartSpeedForDegreesSynced{degrees: 88, speed_l: 75, speed_r: 35}
     }, <<0x81, 0x10, 0x11, 0x0C, 88, 0x00, 0x00, 0x00, 75, 35, 100, 127, 0x00>>},
    {"MSG-13", "a GotoAbsolutePosition",
     %Message.PortOutputCommand{
       port: 0,
       command: %Output.GotoAbsolutePosition{abs_pos: -90, speed: 30, end_state: :hold}
     }, <<0x81, 0x00, 0x11, 0x0D, 0xA6, 0xFF, 0xFF, 0xFF, 30, 100, 126, 0x00>>},
    {"MSG-13", "a GotoAbsolutePosition(AbsPos1, AbsPos2)",
     %Message.PortOutputCommand{
       port: 0x10,
       command: %Output.GotoAbsolutePositionSynced{abs_pos1: 90, abs_pos2: -90, speed: 30}
     },
     <<0x81, 0x10, 0x11, 0x0E, 90, 0x00, 0x00, 0x00, 0xA6, 0xFF, 0xFF, 0xFF, 30, 100, 127, 0x00>>},
    {"MSG-13", "a PresetEncoder(LeftPosition, RightPosition)",
     %Message.PortOutputCommand{
       port: 0x10,
       command: %Output.PresetEncoderSynced{left_position: 0, right_position: -1}
     }, <<0x81, 0x10, 0x11, 0x14, 0::32, 0xFF, 0xFF, 0xFF, 0xFF>>},
    {"MSG-13", "a WriteDirect",
     %Message.PortOutputCommand{port: 0, command: %Output.WriteDirect{payload: <<0xD4, 0x11>>}},
     <<0x81, 0x00, 0x11, 0x50, 0xD4, 0x11, 0x3A>>},
    {"MSG-13", "a WriteDirectModeData",
     %Message.PortOutputCommand{
       port: 0x32,
       command: %Output.WriteDirectModeData{mode: 1, payload: <<0x30, 0x47, 0x55>>}
     }, <<0x81, 0x32, 0x11, 0x51, 0x01, 0x30, 0x47, 0x55>>},
    {"MSG-13", "an undocumented sub command",
     %Message.PortOutputCommand{
       port: 0,
       command: %Output.Unknown{sub_command: 0x60, payload: <<1, 2>>}
     }, <<0x81, 0x00, 0x11, 0x60, 0x01, 0x02>>},
    {"MSG-13", "a buffered output command without feedback",
     %Message.PortOutputCommand{
       port: 0,
       startup: :buffer_if_necessary,
       completion: :no_action,
       command: %Output.StartSpeed{speed: 50}
     }, <<0x81, 0x00, 0x00, 0x07, 50, 100, 0x00>>},

    # Port Output Command Feedback
    {"MSG-15", "feedback for one port",
     %Message.PortOutputCommandFeedback{
       feedback: [{0, [:buffer_empty_command_completed, :idle]}]
     }, <<0x82, 0x00, 0x0A>>},
    {"MSG-15", "feedback for three ports",
     %Message.PortOutputCommandFeedback{
       feedback: [
         {0, [:buffer_empty_command_in_progress]},
         {1, [:current_command_discarded, :idle]},
         {2, [:busy_full]}
       ]
     }, <<0x82, 0x00, 0x01, 0x01, 0x0C, 0x02, 0x10>>}
  ]

  for {requirement, name, message, bytes} <- @examples do
    describe "Given #{name}" do
      @describetag spec: [requirement, "ARCH-5", "ARCH-7", "ARCH-8", "DEC-4", "ENC-3"]

      test "when encoded, then it produces the documented bytes" do
        assert Message.encode(unquote(Macro.escape(message))) == unquote(bytes)
      end

      test "when its bytes are decoded, then the message is restored" do
        assert Message.decode(unquote(bytes)) == {:ok, unquote(Macro.escape(message))}
      end
    end
  end

  describe "Given the examples above" do
    test "when counted, then every message type in the protocol is covered" do
      covered = @examples |> Enum.map(fn {_, _, message, _} -> Message.id(message) end)

      assert Enum.sort(Enum.uniq(covered)) ==
               [0x01, 0x02, 0x03, 0x04, 0x05, 0x08, 0x10, 0x11, 0x12, 0x13] ++
                 [0x21, 0x22, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x61, 0x81, 0x82]
    end

    @tag spec: "MSG-1"
    test "when counted, then every hub property has a typed value" do
      covered =
        for {"MSG-1", _, %{operation: :update, property: property}, _} <- @examples, do: property

      assert Enum.sort(covered) ==
               Enum.sort(Keyword.keys(ExLWP.Enums.values(:hub_property)))
    end

    @tag spec: "MSG-8"
    test "when counted, then every mode information type has a typed value" do
      covered =
        for {_, _, %Message.PortModeInformation{information_type: t}, _} <- @examples, do: t

      assert Enum.sort(covered) ==
               Enum.sort(Keyword.keys(ExLWP.Enums.values(:mode_information_type)))
    end

    @tag spec: "MSG-6"
    test "when counted, then every H/W NetWork command is covered" do
      covered = for {_, _, %Message.HwNetworkCommand{command: c}, _} <- @examples, do: c

      assert Enum.sort(covered) ==
               Enum.sort(Keyword.keys(ExLWP.Enums.values(:hw_network_command)))
    end

    @tag spec: "MSG-13"
    test "when counted, then every documented output sub command is covered" do
      covered =
        for {_, _, %Message.PortOutputCommand{command: %module{}}, _} <- @examples,
            module != Output.Unknown,
            uniq: true,
            do: module

      assert length(covered) == 14
    end
  end

  describe "Given values padded with zeros, as some hubs send them" do
    @describetag spec: ["MSG-1", "MSG-8"]

    test "when a name is decoded, then the padding is removed" do
      assert {:ok, %{value: "POWER"}} = Message.decode(<<0x44, 0, 0, 0x00, "POWER", 0, 0, 0>>)
      assert {:ok, %{value: "Hub"}} = Message.decode(<<0x01, 0x01, 0x06, "Hub", 0, 0>>)
    end
  end

  describe "Given a port value for a mode with a known value format" do
    @describetag spec: "MSG-11"

    test "when its value is decoded with the format, then the numbers are returned" do
      {:ok, %Message.PortModeInformation{value: format}} =
        Message.decode(<<0x44, 0x00, 0x02, 0x80, 1, 2, 4, 0>>)

      {:ok, %Message.PortValueSingle{value: value}} =
        Message.decode(<<0x45, 0x00, 0x68, 0x01, 0x00, 0x00>>)

      assert ValueFormat.decode(format, value) == {:ok, [360]}
    end
  end

  describe "Given an enumeration or bit-field value without a documented name" do
    @describetag spec: "DEC-3"

    test "when a hub action is decoded, then the action is an integer" do
      assert Message.decode(<<0x02, 0x07>>) == {:ok, %Message.HubAction{action: 0x07}}
    end

    test "when an attached I/O is decoded, then its type is an integer" do
      assert {:ok, %Message.HubAttachedIO{io_type: 0x0042}} =
               Message.decode(<<0x04, 0x00, 0x02, 0x42, 0x00, 0x00, 0x01>>)
    end

    test "when an error for an unknown command is decoded, then the command is an integer" do
      assert Message.decode(<<0x05, 0x99, 0x05>>) ==
               {:ok,
                %Message.GenericError{command_type: 0x99, error_code: :command_not_recognized}}
    end

    test "when feedback with an unnamed bit is decoded, then the bit is an integer" do
      assert Message.decode(<<0x82, 0x00, 0x48>>) ==
               {:ok, %Message.PortOutputCommandFeedback{feedback: [{0, [:idle, 0x40]}]}}
    end

    test "when an unknown hub property is decoded, then its value is kept as bytes" do
      assert Message.decode(<<0x01, 0x20, 0x06, 1, 2>>) ==
               {:ok, %Message.HubProperty{property: 0x20, operation: :update, value: <<1, 2>>}}
    end

    test "when it is decoded and encoded again, then the bytes are the same" do
      for bytes <- [<<0x02, 0x07>>, <<0x05, 0x99, 0x05>>, <<0x82, 0x00, 0x48>>] do
        {:ok, message} = Message.decode(bytes)
        assert Message.encode(message) == bytes
      end
    end
  end

  describe "Given bytes with an unknown message type" do
    @describetag spec: "DEC-1"

    test "when decoded, then the error names the message type" do
      assert Message.decode(<<0x06, 0x00>>) == {:error, {:unknown_message, 0x06}}
    end
  end

  describe "Given bytes that don't match the documented layout" do
    @describetag spec: "DEC-2"

    @malformed [
      {Message.HubProperty, <<0x01, 0x02, 0x06>>},
      {Message.HubProperty, <<0x01, 0x01, 0x05, "extra">>},
      {Message.HubAction, <<0x02>>},
      {Message.HubAlert, <<0x03, 0x01, 0x04>>},
      {Message.HubAttachedIO, <<0x04, 0x00, 0x01, 0x27>>},
      {Message.HubAttachedIO, <<0x04, 0x00, 0x07>>},
      {Message.GenericError, <<0x05, 0x81>>},
      {Message.HwNetworkCommand, <<0x08, 0x04>>},
      {Message.GoIntoBootMode, <<0x10, "LPF2-Boom">>},
      {Message.LockMemory, <<0x11>>},
      {Message.LockStatusRequest, <<0x12, 0x00>>},
      {Message.PortInformation, <<0x43, 0x00, 0x02, 0x16>>},
      {Message.PortModeInformation, <<0x44, 0x00, 0x00, 0x01, 0x00>>},
      {Message.PortInputFormatSetupSingle, <<0x41, 0x01, 0x02, 0x05, 0x00, 0x00, 0x00, 0x02>>},
      {Message.VirtualPortSetup, <<0x61, 0x02, 0x00>>},
      {Message.PortOutputCommand, <<0x81, 0x00, 0x11, 0x07, 50>>},
      {Message.PortOutputCommand, <<0x81, 0x00, 0x11, 0x50, 0xD4, 0x11, 0x00>>},
      {Message.PortOutputCommandFeedback, <<0x82, 0x00>>}
    ]

    for {module, bytes} <- @malformed do
      test "when #{inspect(bytes)} is decoded, then the error names #{inspect(module)}" do
        assert Message.decode(unquote(bytes)) == {:error, {:malformed, unquote(module)}}
      end
    end
  end

  describe "Given empty bytes" do
    @describetag spec: "DEC-2"

    test "when decoded, then an error is returned" do
      assert Message.decode(<<>>) == {:error, :empty}
    end
  end

  describe "Given a field that doesn't fit the protocol" do
    @describetag spec: "ENC-1"

    @invalid [
      {"a port above 255",
       %Message.PortInformationRequest{port: 256, information_type: :mode_info}},
      {"a negative delta interval",
       %Message.PortInputFormatSetupSingle{port: 0, mode: 0, delta_interval: -1}},
      {"an advertising name of 15 bytes",
       %Message.HubProperty{
         property: :advertising_name,
         operation: :set,
         value: "123456789012345"
       }},
      {"a mode name of 12 bytes",
       %Message.PortModeInformation{
         port: 0,
         mode: 0,
         information_type: :name,
         value: "ABCDEFGHIJKL"
       }},
      {"a MAC address of 5 bytes",
       %Message.HubProperty{
         property: :primary_mac_address,
         operation: :update,
         value: <<1, 2, 3, 4, 5>>
       }},
      {"a family above 15",
       %Message.HwNetworkCommand{command: :extended_family_set, family: 16, subfamily: 1}},
      {"a mode above 15", %Message.PortValueCombined{port: 0, mode_datasets: [16], value: <<>>}},
      {"a speed above 100",
       %Message.PortOutputCommand{port: 0, command: %Output.StartSpeed{speed: 101}}},
      {"a max power above 100",
       %Message.PortOutputCommand{port: 0, command: %Output.StartSpeed{speed: 50, max_power: 101}}},
      {"a time above 10000 ms",
       %Message.PortOutputCommand{port: 0, command: %Output.SetAccTime{time: 10_001}}},
      {"a position beyond 32 bits",
       %Message.PortOutputCommand{
         port: 0,
         command: %Output.GotoAbsolutePosition{abs_pos: 1 <<< 32, speed: 10}
       }},
      {"an unknown enum name", %Message.HubAction{action: :explode}},
      {"an unknown flag",
       %Message.PortOutputCommand{
         port: 0,
         command: %Output.StartSpeed{speed: 1, use_profile: [:fast]}
       }},
      {"no ports in feedback", %Message.PortOutputCommandFeedback{feedback: []}}
    ]

    for {name, message} <- @invalid do
      test "when #{name} is encoded, then an ArgumentError is raised" do
        assert_raise ArgumentError, fn -> Message.encode(unquote(Macro.escape(message))) end
      end
    end
  end

  describe "Given messages with a safety string or checksum" do
    @describetag spec: "ENC-2"

    test "when encoded, then the safety string or checksum is added" do
      assert Message.encode(%Message.GoIntoBootMode{}) == <<0x10, "LPF2-Boot">>
      assert Message.encode(%Message.LockMemory{}) == <<0x11, "Lock-Mem">>

      assert %Message.PortOutputCommand{
               port: 0,
               command: %Output.WriteDirect{payload: <<0xD4, 0x11>>}
             }
             |> Message.encode()
             |> binary_part(4, 3) == <<0xD4, 0x11, 0x3A>>
    end
  end
end
