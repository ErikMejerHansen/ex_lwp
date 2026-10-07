defmodule ExLWP.AdvertisementTest do
  use ExUnit.Case, async: true

  @moduletag spec: "BLE-2"

  alias ExLWP.Advertisement

  @data <<0x00, 0x41, 0x0F, 0xFB, 0x22, 0x00>>

  describe "Given a hub's manufacturer data" do
    test "when decoded, then the documented fields are returned" do
      assert Advertisement.decode(@data) ==
               {:ok,
                %Advertisement{
                  button: :released,
                  system_type: :two_port_hub,
                  device_capabilities: [
                    :central_role,
                    :peripheral_role,
                    :lpf2_devices,
                    :remote_controller
                  ],
                  last_network: 251,
                  status: [:can_be_central, :request_window],
                  option: 0
                }}
    end

    test "when prefixed with the manufacturer ID or the whole data structure, then it decodes the same" do
      assert Advertisement.decode(<<0x97, 0x03, @data::binary>>) == Advertisement.decode(@data)

      assert Advertisement.decode(<<0x09, 0xFF, 0x97, 0x03, @data::binary>>) ==
               Advertisement.decode(@data)
    end

    test "when it has the wrong size, then an error is returned" do
      assert Advertisement.decode(<<0x00, 0x41>>) == {:error, :invalid_manufacturer_data}
    end
  end

  describe "Given a scan for hubs" do
    test "when filtering by manufacturer, then LEGO's ID is available" do
      assert Advertisement.manufacturer_id() == 0x0397
    end
  end
end
