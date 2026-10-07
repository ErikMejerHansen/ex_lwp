defmodule ExLWP.Advertisement do
  @moduledoc """
  Decodes the Manufacturer Data a hub sends when advertising.

  BLE libraries hand over manufacturer data in different shapes. `decode/1`
  takes any of them:

    * the 6 bytes after the manufacturer ID, as Web Bluetooth gives them
    * those bytes prefixed with the manufacturer ID, `0x0397`, little endian
    * the whole advertising data structure, starting with its length, `0x09`,
      and type, `0xFF`

  For example, a Boost hub with its button pressed:

      iex> ExLWP.Advertisement.decode(<<0x01, 0x40, 0x06, 0x00, 0x41, 0x00>>)
      {:ok,
       %ExLWP.Advertisement{
         button: :pressed,
         system_type: :boost_hub,
         device_capabilities: [:peripheral_role, :lpf2_devices],
         last_network: 0,
         status: [:can_be_peripheral, :request_connect],
         option: 0
       }}

  See [Advertising](https://lego.github.io/lego-ble-wireless-protocol-docs/#advertising).
  """

  alias ExLWP.Enums

  @manufacturer_id 0x0397

  defstruct [:button, :system_type, :device_capabilities, :last_network, :status, option: 0]

  @type t :: %__MODULE__{
          button: :pressed | :released | 0..0xFF,
          system_type: atom() | 0..0xFF,
          device_capabilities: Enums.flags(),
          last_network: 0..0xFF,
          status: Enums.flags(),
          option: 0..0xFF
        }

  @doc "Returns LEGO's manufacturer ID, `0x0397`, to filter BLE scans by."
  @spec manufacturer_id() :: 0x0397
  def manufacturer_id, do: @manufacturer_id

  @doc "Decodes the manufacturer data of a hub's advertisement."
  @spec decode(binary()) :: {:ok, t()} | {:error, :invalid_manufacturer_data}
  def decode(<<0x09, 0xFF, @manufacturer_id::little-16, data::binary-size(6)>>), do: decode(data)
  def decode(<<@manufacturer_id::little-16, data::binary-size(6)>>), do: decode(data)

  def decode(<<button, system_type, capabilities, last_network, status, option>>) do
    {:ok,
     %__MODULE__{
       button: Enums.to_name(:button_state, button),
       system_type: Enums.to_name(:system_type, system_type),
       device_capabilities: Enums.to_flags(:device_capabilities, capabilities),
       last_network: last_network,
       status: Enums.to_flags(:advertising_status, status),
       option: option
     }}
  end

  def decode(_data), do: {:error, :invalid_manufacturer_data}
end
