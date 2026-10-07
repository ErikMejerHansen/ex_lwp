defmodule ExLWP.ValueFormatTest do
  use ExUnit.Case, async: true

  @moduletag spec: "MSG-11"

  alias ExLWP.ValueFormat

  describe "Given a value format" do
    test "when values of each dataset type are decoded, then they are signed and little endian" do
      assert ValueFormat.decode(%ValueFormat{type: :int8}, <<0xCE>>) == {:ok, [-50]}
      assert ValueFormat.decode(%ValueFormat{type: :int16}, <<0x18, 0xFC>>) == {:ok, [-1000]}

      assert ValueFormat.decode(%ValueFormat{type: :int32}, <<0x00, 0x00, 0x01, 0x00>>) ==
               {:ok, [65_536]}

      assert ValueFormat.decode(%ValueFormat{type: :float}, <<1.5::float-little-32>>) ==
               {:ok, [1.5]}
    end

    test "when several datasets are decoded, then each is returned in order" do
      format = %ValueFormat{datasets: 3, type: :int16}

      assert ValueFormat.decode(format, <<1, 0, 2, 0, 0xFF, 0xFF>>) == {:ok, [1, 2, -1]}
    end

    test "when the bytes are the wrong size, then an error is returned" do
      assert ValueFormat.decode(%ValueFormat{type: :int32}, <<1, 2>>) == {:error, :size_mismatch}
    end

    test "when a float is not a number, then it decodes to an atom" do
      format = %ValueFormat{datasets: 3, type: :float}
      bytes = <<0, 0, 0x80, 0x7F, 0, 0, 0x80, 0xFF, 0, 0, 0xC0, 0x7F>>

      assert ValueFormat.decode(format, bytes) == {:ok, [:infinity, :neg_infinity, :nan]}
    end

    test "when values are encoded and decoded, then they are restored" do
      for {type, values} <- [
            int8: [-128, 127],
            int16: [-32_768, 32_767],
            int32: [-1, 1],
            float: [0.5, -2.0]
          ] do
        format = %ValueFormat{datasets: 2, type: type}
        assert ValueFormat.decode(format, ValueFormat.encode(format, values)) == {:ok, values}
      end
    end

    test "when a value doesn't fit, then an ArgumentError is raised" do
      assert_raise ArgumentError, fn -> ValueFormat.encode(%ValueFormat{type: :int8}, [128]) end
      assert_raise ArgumentError, fn -> ValueFormat.encode(%ValueFormat{datasets: 2}, [1]) end
    end
  end

  describe "Given a Port Value message holding values for two ports" do
    test "when split with the size of each format, then each port's values decode" do
      {:ok, %ExLWP.Message.PortValueSingle{port: 0, value: bytes}} =
        ExLWP.Message.decode(<<0x45, 0x00, 0x10, 0x00, 0x01, 0xCE>>)

      speed = %ValueFormat{type: :int16}
      size = ValueFormat.size(speed)
      <<first::binary-size(size), 0x01, second::binary>> = bytes

      assert ValueFormat.decode(speed, first) == {:ok, [16]}
      assert ValueFormat.decode(%ValueFormat{type: :int8}, second) == {:ok, [-50]}
    end
  end
end
