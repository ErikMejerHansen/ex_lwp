defmodule ExLWP.HeaderTest do
  use ExUnit.Case, async: true

  alias ExLWP.Header

  describe "Given a message" do
    @describetag spec: "FRAME-1"

    test "when encoded, then it starts with its length, the hub ID and its message type" do
      assert <<5, 0x00, 0x01, 0x01, 0x05>> =
               ExLWP.encode(ExLWP.Messages.request_hub_property(:advertising_name))
    end

    test "when encoded with a hub ID, then the header holds that hub ID" do
      assert <<5, 0x07, 0x01, 0x01, 0x05>> = ExLWP.encode(<<0x01, 0x01, 0x05>>, hub_id: 7)
      assert {:ok, 7, <<0x01, 0x01, 0x05>>} = Header.unpack(<<5, 0x07, 0x01, 0x01, 0x05>>)
    end
  end

  describe "Given a message of 127 bytes or less, header included" do
    @describetag spec: "FRAME-2"

    test "when encoded, then its length takes one byte" do
      message = <<0x45, 0x00, :binary.copy(<<0xAA>>, 123)::binary>>

      assert <<127, 0x00, ^message::binary>> = ExLWP.encode(message)
    end
  end

  describe "Given a message longer than 127 bytes, header included" do
    @describetag spec: "FRAME-3"

    test "when its length is encoded, then it matches the documented examples" do
      assert Header.encode_length(128) == <<0b1000_0000, 0b0000_0001>>
      assert Header.encode_length(129) == <<0b1000_0001, 0b0000_0001>>
      assert Header.encode_length(130) == <<0b1000_0010, 0b0000_0001>>
    end

    test "when encoded, then its length takes two bytes and counts both" do
      # With a 1 byte length this would be 128 bytes: one too many. The 2 byte
      # length adds another byte.
      message = <<0x45, 0x00, :binary.copy(<<0xAA>>, 124)::binary>>

      assert <<0x81, 0x01, 0x00, ^message::binary>> = frame = ExLWP.encode(message)
      assert byte_size(frame) == 129
      assert {:ok, %ExLWP.Message.PortValueSingle{}} = ExLWP.decode(frame)
    end

    test "when it is too long for the protocol, then an ArgumentError is raised" do
      assert_raise ArgumentError, fn -> ExLWP.encode(:binary.copy(<<0x45>>, 0x7FFF)) end
    end
  end

  describe "Given no hub ID" do
    @describetag spec: "FRAME-4"

    test "when a message is encoded, then the hub ID is 0x00" do
      assert <<_length, 0x00, _rest::binary>> = ExLWP.encode(ExLWP.Messages.switch_off())
    end
  end

  describe "Given a stream of bytes" do
    @describetag spec: "FRAME-5"

    setup do
      messages = [
        ExLWP.Messages.request_hub_property(:battery_voltage),
        ExLWP.Messages.start_speed_for_degrees(0, 720, 75),
        %ExLWP.Message.PortValueSingle{port: 0, value: :binary.copy(<<1>>, 200)},
        %ExLWP.Message.HubAttachedIO{port: 1, event: :detached}
      ]

      stream = messages |> Enum.map(&ExLWP.encode/1) |> IO.iodata_to_binary()
      %{messages: messages, stream: stream}
    end

    test "when received all at once, then every message is decoded",
         %{messages: messages, stream: stream} do
      assert ExLWP.decode_stream(stream) == {Enum.map(messages, &{:ok, &1}), <<>>}
    end

    test "when received in 20 byte packets, then every message is decoded",
         %{messages: messages, stream: stream} do
      size = byte_size(stream)

      packets =
        for start <- 0..(size - 1)//20, do: binary_part(stream, start, min(20, size - start))

      {decoded, rest} =
        Enum.reduce(packets, {[], <<>>}, fn packet, {decoded, rest} ->
          {new, rest} = ExLWP.decode_stream(rest <> packet)
          {decoded ++ new, rest}
        end)

      assert decoded == Enum.map(messages, &{:ok, &1})
      assert rest == <<>>
    end

    test "when it ends with half a message, then the half is handed back" do
      assert ExLWP.decode_stream(<<0x05, 0x00, 0x01>>) == {[], <<0x05, 0x00, 0x01>>}
      assert ExLWP.decode_stream(<<0x81>>) == {[], <<0x81>>}
    end
  end

  describe "Given a message whose length field doesn't match its size" do
    @describetag spec: "FRAME-6"

    test "when decoded, then an error is returned" do
      assert ExLWP.decode(<<0x09, 0x00, 0x01, 0x01, 0x05>>) == {:error, :invalid_length}
      assert ExLWP.decode(<<0x04, 0x00, 0x01, 0x01, 0x05>>) == {:error, :invalid_length}
      assert ExLWP.decode(<<0x02, 0x00>>) == {:error, :invalid_length}
      assert ExLWP.decode(<<>>) == {:error, :invalid_length}
    end

    test "when it is in a stream, then the rest of the stream fails to decode instead of hanging" do
      assert {[{:error, :invalid_length}], <<>>} = ExLWP.decode_stream(<<0x00, 0x01, 0x02>>)
    end
  end
end
