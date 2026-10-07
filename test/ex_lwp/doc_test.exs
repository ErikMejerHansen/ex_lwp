defmodule ExLWP.DocTest do
  use ExUnit.Case, async: true

  doctest ExLWP
  doctest ExLWP.Advertisement
  doctest ExLWP.Enums
  doctest ExLWP.Header
  doctest ExLWP.Message
  doctest ExLWP.Messages
  doctest ExLWP.Output
  doctest ExLWP.ValueFormat
  doctest ExLWP.Version
end
