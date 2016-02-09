defmodule LzStringTest.Reference.Test do
  use ExUnit.Case, async: true
  import TestHelper
  import LZString

  setup do
    {:ok, port: TestHelper.lz_string_node_port}
  end

  test "compress/1 should match output from the reference implementation for random strings", %{port: port} do
    Enum.each 1..2000, fn _ ->
      1000
      |> :crypto.rand_bytes
      |> Base.encode16
      |> assert_same_as_node_compress(port)
    end
  end

  test "compress/1 should match output from the reference implementation for repeated ascii", %{port: port} do
    Enum.each 1..2000, &(assert_same_as_node_compress String.ljust("", &1, ?a), port)
  end

  test "compress/1 should match output from the reference implementation for repeated multibyte char strings", %{port: port} do
    Enum.each 1..2000, &(assert_same_as_node_compress String.ljust("", &1, ?猫), port)
  end


  # compress using node, and decompress using elixir

  test "decompress/1 should be able to decompress random strings from the reference implementation's compressToUint8Array/1", %{port: port} do
    Enum.each(1..2000, fn _ ->
      str = 1000
      |> :crypto.rand_bytes
      |> Base.encode16

      assert str == compress_to_binary_with_node(port, str) |> decompress
    end)
  end

  test "decompress/1 should be able to decompress multi-byte utf8 from the reference implementation's compressToUint8Array/1", %{port: port} do
    str = "今日は 今日は 今日は 今日は 今日は 今日は"
    assert str == compress_to_binary_with_node(port, str) |> decompress
  end

  # compress to lz-string pseudo-base64 using node, and decompress using elixir

  test "decompress_base64/1 should be able to decompress random strings from the reference implementation's compressToBase64/1", %{port: port} do
    Enum.each(1..2000, fn _ ->
      str = 1000
      |> :crypto.rand_bytes
      |> Base.encode16

      assert str == compress_to_base64_with_node(port, str) |> decompress_base64
    end)
  end

  test "decompress_base64/1 should be able to decompress multi-byte utf8 from the reference implementation's compressToBase64/1", %{port: port} do
    str = "今日は 今日は 今日は 今日は 今日は 今日は"
    assert str == compress_to_base64_with_node(port, str) |> decompress_base64
  end

  # compress to base64, and decompress using node

  test "the reference implementation's decompressFromBase64/1 should be able to random strings from compress_base64/1", %{port: port} do
    Enum.each(1..2000, fn _ ->
      str = 1000
      |> :crypto.rand_bytes
      |> Base.encode16

      assert str == compress_base64(str) |> decompress_base64_with_node(port)
    end)
  end

  test "the reference implementation's decompressFromBase64/1 should be able to decompress multi-byte utf8 from compress_base64/1", %{port: port} do
    str = "今日は 今日は 今日は 今日は 今日は 今日は"
    assert str == compress_base64(str) |> decompress_base64_with_node(port)
  end

end
