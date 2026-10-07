defmodule ExLWP.VersionTest do
  use ExUnit.Case, async: true

  @moduletag spec: "MSG-16"

  alias ExLWP.Version

  describe "Given the documented version 1.7.37.1510" do
    test "when its bytes are decoded, then the numbers are restored" do
      # Byte 3 (MSB): 0x17, byte 2: 0x37, byte 1: 0x15, byte 0 (LSB): 0x10
      <<value::little-32>> = <<0x10, 0x15, 0x37, 0x17>>

      assert Version.decode(value) == %Version{major: 1, minor: 7, bugfix: 37, build: 1510}
    end

    test "when encoded, then it produces the documented value" do
      assert Version.encode(%Version{major: 1, minor: 7, bugfix: 37, build: 1510}) == 0x17371510
    end

    test "when printed, then it reads as LEGO presents it" do
      assert to_string(Version.decode(0x17371510)) == "1.7.37.1510"
      assert to_string(Version.decode(0x10000004)) == "1.0.00.0004"
    end
  end

  describe "Given an LWP version" do
    test "when decoded, then it has a major and minor number" do
      assert Version.decode_lwp(0x0300) == %Version{major: 3, minor: 0}
      assert Version.decode_lwp(0x0123) == %Version{major: 1, minor: 23}
      assert to_string(Version.decode_lwp(0x0300)) == "3.00"
    end

    test "when encoded, then it is BCD" do
      assert Version.encode_lwp(%Version{major: 1, minor: 23}) == 0x0123
    end
  end

  describe "Given a value that is not a valid version" do
    @describetag spec: ["MSG-16", "DEC-3"]

    test "when decoded, then the integer is returned" do
      assert Version.decode(0x1A000000) == 0x1A000000
      assert Version.decode(0x80000000) == 0x80000000
      assert Version.decode_lwp(0x00FF) == 0x00FF
    end

    test "when encoded, then the integer is passed through" do
      assert Version.encode(0x1A000000) == 0x1A000000
    end
  end

  describe "Given a version with numbers that don't fit" do
    @describetag spec: "ENC-1"

    test "when encoded, then an ArgumentError is raised" do
      assert_raise ArgumentError, fn ->
        Version.encode(%Version{major: 8, minor: 0, bugfix: 0, build: 0})
      end

      assert_raise ArgumentError, fn ->
        Version.encode(%Version{major: 1, minor: 10, bugfix: 0, build: 0})
      end

      assert_raise ArgumentError, fn -> Version.encode_lwp(%Version{major: 100, minor: 0}) end
    end
  end
end
