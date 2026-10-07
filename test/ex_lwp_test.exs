defmodule ExLWPTest do
  use ExUnit.Case, async: true

  alias ExLWP.{Message, Messages, Version}

  describe "Given a client talking to a hub" do
    @describetag spec: ["ARCH-6", "ARCH-8"]

    test "when it asks for the hub's firmware version, then the hub can decode the request" do
      frame = ExLWP.encode(Messages.request_hub_property(:fw_version))

      assert ExLWP.decode(frame) ==
               {:ok, %Message.HubProperty{property: :fw_version, operation: :request_update}}
    end

    test "when the hub replies, then the client can decode the reply" do
      reply = %Message.HubProperty{
        property: :fw_version,
        operation: :update,
        value: %Version{major: 1, minor: 1, bugfix: 0, build: 4}
      }

      assert reply |> ExLWP.encode() |> ExLWP.decode() == {:ok, reply}
    end

    test "when it starts a motor, then the hub can decode the command" do
      command = Messages.start_speed(0, 75, max_power: 80, use_profile: [:acceleration])

      assert command |> ExLWP.encode() |> ExLWP.decode() == {:ok, command}
    end
  end

  describe "Given bytes as a Powered Up hub sends them" do
    @describetag spec: ["ARCH-5", "ARCH-8"]

    test "when a motor is attached, then the attached I/O is decoded" do
      bytes = <<0x0F, 0x00, 0x04, 0x00, 0x01, 0x27, 0x00>> <> <<0, 0, 0, 0x10, 0, 0, 0, 0x10>>

      assert {:ok,
              %Message.HubAttachedIO{
                port: 0,
                event: :attached,
                io_type: :internal_motor_with_tacho,
                hardware_revision: %Version{major: 1, minor: 0, bugfix: 0, build: 0}
              }} = ExLWP.decode(bytes)
    end

    test "when a command completes, then the feedback is decoded" do
      assert ExLWP.decode(<<0x05, 0x00, 0x82, 0x00, 0x0A>>) ==
               {:ok,
                %Message.PortOutputCommandFeedback{
                  feedback: [{0, [:buffer_empty_command_completed, :idle]}]
                }}
    end
  end

  describe "Given a message written as a raw bitstring" do
    @describetag spec: "ARCH-7"

    test "when encoded, then it produces the same bytes as the struct" do
      assert ExLWP.encode(<<0x02, 0x01>>) == ExLWP.encode(Messages.switch_off())
    end

    test "when decoded into a struct, then the fields are filled in" do
      assert Message.decode(<<0x41, 0x00, 0x02, 0x01, 0x00, 0x00, 0x00, 0x01>>) ==
               {:ok,
                %Message.PortInputFormatSetupSingle{
                  port: 0,
                  mode: 2,
                  delta_interval: 1,
                  notification_enabled: true
                }}
    end
  end

  describe "Given random bytes" do
    @describetag spec: "DEC-5"

    test "when decoded, then a result or an error tuple is returned, never an exception" do
      :rand.seed(:exsss, {1, 2, 3})

      for _ <- 1..20_000 do
        size = :rand.uniform(24)
        body = :rand.bytes(size)

        type =
          Enum.random([
            0x01,
            0x02,
            0x03,
            0x04,
            0x05,
            0x08,
            0x13,
            0x43,
            0x44,
            0x45,
            0x48,
            0x81,
            0x82
          ])

        for bytes <- [<<size + 3, 0, type, body::binary>>, :rand.bytes(size)] do
          assert {status, _} = ExLWP.decode(bytes)
          assert status in [:ok, :error]
          {results, rest} = ExLWP.decode_stream(bytes)
          assert is_list(results) and is_binary(rest)
        end
      end
    end
  end

  describe "Given a BLE library to connect with" do
    @describetag spec: "BLE-1"

    test "when looking for the hub, then the service and characteristic UUIDs are available" do
      assert ExLWP.service_uuid() == "00001623-1212-efde-1623-785feabcd123"
      assert ExLWP.characteristic_uuid() == "00001624-1212-efde-1623-785feabcd123"
    end
  end

  describe "Given the project documentation" do
    @describetag spec: "DOC-2"

    test "when read, then it states there is no affiliation with The LEGO Group" do
      {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} = Code.fetch_docs(ExLWP)

      for doc <- [moduledoc, File.read!("README.md")] do
        assert doc =~ "not affiliated with"
        assert doc =~ "The LEGO Group"
      end
    end
  end
end
