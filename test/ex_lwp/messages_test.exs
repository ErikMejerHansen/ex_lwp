defmodule ExLWP.MessagesTest do
  use ExUnit.Case, async: true

  @moduletag spec: "ARCH-6"

  import Bitwise

  alias ExLWP.{Message, Messages, Output}

  describe "Given a client that wants to talk to the hub" do
    test "when it builds hub property messages, then they have the right operations" do
      assert %Message.HubProperty{property: :battery_voltage, operation: :enable_updates} =
               Messages.enable_hub_property_updates(:battery_voltage)

      assert %Message.HubProperty{operation: :disable_updates} =
               Messages.disable_hub_property_updates(:rssi)

      assert %Message.HubProperty{operation: :reset} =
               Messages.reset_hub_property(:advertising_name)

      assert %Message.HubProperty{property: :advertising_name, operation: :set, value: "Brick"} =
               Messages.set_advertising_name("Brick")
    end

    test "when it builds hub actions and alerts, then they encode to the documented bytes" do
      assert Message.encode(Messages.switch_off()) == <<0x02, 0x01>>
      assert Message.encode(Messages.disconnect()) == <<0x02, 0x02>>
      assert Message.encode(Messages.hub_action(:activate_busy_indication)) == <<0x02, 0x05>>
      assert Message.encode(Messages.enable_hub_alert(:low_voltage)) == <<0x03, 0x01, 0x01>>
      assert Message.encode(Messages.disable_hub_alert(:low_voltage)) == <<0x03, 0x01, 0x02>>
      assert Message.encode(Messages.request_hub_alert(:high_current)) == <<0x03, 0x02, 0x03>>
    end

    test "when it builds firmware update messages, then they encode to the documented bytes" do
      assert Message.encode(Messages.go_into_boot_mode()) == <<0x10, "LPF2-Boot">>
      assert Message.encode(Messages.lock_memory()) == <<0x11, "Lock-Mem">>
      assert Message.encode(Messages.lock_status_request()) == <<0x12>>
    end

    test "when it builds port information requests, then they encode to the documented bytes" do
      assert Message.encode(Messages.port_information_request(1, :possible_mode_combinations)) ==
               <<0x21, 0x01, 0x02>>

      assert Message.encode(Messages.port_mode_information_request(1, 0, :name)) ==
               <<0x22, 0x01, 0x00, 0x00>>
    end

    test "when it sets up a port in combined mode, then each step encodes to the documented bytes" do
      steps = [
        Messages.combined_mode_lock(1),
        Messages.port_input_format_setup(1, 1, 1),
        Messages.port_input_format_setup(1, 2, 1),
        Messages.combined_mode_set(1, 0, [{1, 0}, {2, 0}]),
        Messages.combined_mode_unlock(1),
        Messages.combined_mode_unlock(1, false),
        Messages.combined_mode_reset(1)
      ]

      assert Enum.map(steps, &Message.encode/1) == [
               <<0x42, 0x01, 0x02>>,
               <<0x41, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x01>>,
               <<0x41, 0x01, 0x02, 0x01, 0x00, 0x00, 0x00, 0x01>>,
               <<0x42, 0x01, 0x01, 0x00, 0x10, 0x20>>,
               <<0x42, 0x01, 0x03>>,
               <<0x42, 0x01, 0x04>>,
               <<0x42, 0x01, 0x06>>
             ]
    end

    test "when it sets up a virtual port, then it encodes to the documented bytes" do
      assert Message.encode(Messages.virtual_port_connect(0, 1)) == <<0x61, 0x01, 0x00, 0x01>>
      assert Message.encode(Messages.virtual_port_disconnect(0x10)) == <<0x61, 0x00, 0x10>>
    end

    test "when it builds H/W NetWork commands, then they carry their fields" do
      assert Message.encode(Messages.hw_network_command(:get_family)) == <<0x08, 0x06>>

      assert Message.encode(Messages.hw_network_command(:family_set, family: 3)) ==
               <<0x08, 0x04, 0x03>>
    end
  end

  describe "Given motor commands" do
    @describetag spec: ["ARCH-6", "MSG-13"]

    test "when built with defaults, then they execute immediately with feedback, full power and brake" do
      assert %Message.PortOutputCommand{
               port: 0,
               startup: :execute_immediately,
               completion: :command_feedback,
               command: %Output.StartSpeedForTime{
                 time: 1000,
                 speed: 50,
                 max_power: 100,
                 end_state: :brake,
                 use_profile: []
               }
             } = Messages.start_speed_for_time(0, 1000, 50)
    end

    test "when built with options, then the options are used" do
      command =
        Messages.goto_absolute_position(0, 90, 30,
          max_power: 50,
          end_state: :hold,
          use_profile: [:acceleration],
          startup: :buffer_if_necessary,
          completion: :no_action
        )

      assert Message.encode(command) ==
               <<0x81, 0x00, 0x00, 0x0D, 90, 0x00, 0x00, 0x00, 30, 50, 126, 0x01>>
    end

    test "when an option doesn't apply to a command, then it is ignored" do
      assert %{command: %Output.StartSpeed{speed: 10}} =
               Messages.start_speed(0, 10, end_state: :hold)
    end

    test "when every motor command is built, then each encodes" do
      commands = [
        Messages.start_power_synced(0x10, 50, -50),
        Messages.set_acc_time(0, 500),
        Messages.set_dec_time(0, 500, 1),
        Messages.start_speed(0, -100),
        Messages.start_speed_synced(0x10, 50, 30),
        Messages.start_speed_for_time_synced(0x10, 1000, 50, 30),
        Messages.start_speed_for_degrees(0, 90, 50),
        Messages.start_speed_for_degrees_synced(0x10, 90, 50, -50),
        Messages.goto_absolute_position_synced(0x10, 90, -90, 50),
        Messages.preset_encoder_synced(0x10, 0, 0)
      ]

      for command <- commands do
        assert {:ok, ^command} = command |> ExLWP.encode() |> ExLWP.decode()
      end
    end

    test "when powers are given as :brake and :float, then they encode as 127 and 0" do
      assert <<0x81, 0x10, 0x11, 0x02, 127, 0>> =
               Message.encode(Messages.start_power_synced(0x10, :brake, :float))
    end
  end

  describe "Given a command the documentation encodes through WriteDirectModeData" do
    @describetag spec: ["MSG-14", "ARCH-6"]

    @examples [
      {"StartPower(Power)", Messages.start_power(1, -50), 0, <<0xCE>>},
      {"StartPower(Power) braking", Messages.start_power(1, :brake), 0, <<127>>},
      {"StartPower(Power) floating", Messages.start_power(1, :float), 0, <<0>>},
      {"PresetEncoder(Position)", Messages.preset_encoder(1, 720), 2, <<0xD0, 0x02, 0x00, 0x00>>},
      {"TiltImpactPreset(PresetValue)", Messages.tilt_impact_preset(1, 3), 3, <<3, 0, 0, 0>>},
      {"TiltConfigOrientation(Orientation)", Messages.tilt_config_orientation(1, :top), 5, <<5>>},
      {"TiltConfigImpact(ImpactThreshold, BumpHoldoff)", Messages.tilt_config_impact(1, 10, 20),
       6, <<10, 20>>},
      {"SetRgbColorNo(ColorNo)", Messages.set_rgb_color_no(0x32, 9), 0, <<9>>},
      {"SetRgbColors(RedColor, GreenColor, BlueColor)",
       Messages.set_rgb_colors(0x32, 0x30, 0x47, 0x55), 1, <<0x30, 0x47, 0x55>>}
    ]

    for {name, command, mode, payload} <- @examples do
      test "when #{name} is built, then it writes the documented mode and payload" do
        assert %Message.PortOutputCommand{
                 command: %Output.WriteDirectModeData{
                   mode: unquote(mode),
                   payload: unquote(payload)
                 }
               } = unquote(Macro.escape(command))
      end
    end

    test "when the documented RGB example is built, then it matches the documented bytes" do
      # "Set RGB LED into RGB mode (0x01) and set the R = 0x30, G = 0x47, B = 0x55"
      assert <<0x81, 0x32, 0x11, 0x51, 0x01, 0x30, 0x47, 0x55>> =
               Message.encode(Messages.set_rgb_colors(0x32, 0x30, 0x47, 0x55))
    end
  end

  describe "Given a command the documentation encodes through WriteDirect" do
    @describetag spec: ["MSG-14", "ENC-2", "ARCH-6"]

    test "when GenericZeroSetHardware() is built, then it matches the documented bytes" do
      assert <<0x81, 0x00, 0x11, 0x50, 0xD4, 0x11, 0x3A>> =
               Message.encode(Messages.generic_zero_set_hardware(0))
    end

    test "when TiltFactoryCalibration(Orientation, PassCode) is built, then it matches the documented example" do
      assert <<0x81, 0x00, 0x11, 0x50, 0xD4, 0x02, "Calib-Sensor", 0x77>> =
               Message.encode(Messages.tilt_factory_calibration(0, :z))
    end
  end

  describe "Given values that don't fit" do
    @describetag spec: "ENC-1"

    test "when a command is built, then an ArgumentError is raised" do
      assert_raise ArgumentError, fn -> Messages.start_power(0, 101) end
      assert_raise ArgumentError, fn -> Messages.set_rgb_colors(0, 256, 0, 0) end
      assert_raise ArgumentError, fn -> Messages.preset_encoder(0, 1 <<< 40) end
      assert_raise ArgumentError, fn -> Messages.tilt_config_orientation(0, :sideways) end
    end
  end
end
