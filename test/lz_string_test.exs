defmodule LzStringTest do
  use ExUnit.Case, async: true
  import TestHelper
  import LZString
  doctest LZString

  test "roundtrip repeated single-bute strings" do
    Enum.each 1..2000, &(assert_roundtrip String.ljust("", &1, ?a))
  end

  test "roundtrip repeated multi-byte char strings" do
    Enum.each 1..2000, &(assert_roundtrip String.ljust("", &1, ?猫))
  end

  test "roundtrip random high entropy strings" do
    Enum.each 1..1000, fn _ ->
      1000
      |> random_string
      |> assert_roundtrip
    end
  end

  test "roundtrip random large low entropy string" do
    1_000_000
    |> :crypto.rand_bytes
    |> Base.encode16
    |> assert_roundtrip
  end

  test "compress/1 should be able to handle every valid utf8 character that fits in two bytes" do
    valid_utf8_char_ranges
    |> Enum.flat_map(fn range -> Enum.map(range, &(<< &1 :: utf8 >>)) end)
    |> :erlang.list_to_binary
    |> assert_roundtrip
  end

end
