defmodule TestHelper do

  # chars in the "surrogate pair" range are invalid on their own
  @surrogate_pair_start "D800" |> :erlang.binary_to_integer(16) |> Kernel.-(1)
  @surrogate_pair_stop "DFFF" |> :erlang.binary_to_integer(16) |> Kernel.+(1)
  # UCS-2 is limited to 16 bits
  @max_two_byte :math.pow(2, 16) |> trunc |> Kernel.-(1)

  @valid_utf8_char_ranges [0..@surrogate_pair_start, @surrogate_pair_stop..@max_two_byte]

  defmacro assert_roundtrip(str) do
    quote do
      str = unquote(str)
      roundtrip_str = str |> compress |> decompress
      assert roundtrip_str == str
    end
  end

  defmacro assert_same_as_node_compress(str, port) do
    quote do
      str = unquote(str)
      assert compress(str) == compress_to_binary_with_node(unquote(port), str), str
    end
  end

  def valid_utf8_char_ranges do
    @valid_utf8_char_ranges
  end

  def random_string(size) do
    Enum.map(0..size, fn _ -> random_utf8_char() end)
    |> :erlang.list_to_binary
  end

  def random_utf8_char do
    << random_int_in_range() :: utf8 >>
  end

  def random_int_in_range do
    int = :rand.uniform(@max_two_byte)

    if int_in_range?(int) do
      int
    else
      random_int_in_range()
    end
  end

  defp int_in_range?(i) do
    i <= @surrogate_pair_start || (@surrogate_pair_stop <= i && i <= @max_two_byte)
  end

  # node reference implementation interactions
  # this isn't perfect, but it's ok for our purposes

  def compress_to_base64_with_node(port, str) do
    str = String.replace(str, "'", "\'")
    repl_eval(port, "LZString.compressToBase64('#{str}')")
    |> String.strip(?') #'
  end

  def decompress_base64_with_node(str, port) do
    repl_eval(port, "LZString.decompressFromBase64('#{str}')")
    |> String.strip(?') #'
  end

  def compress_to_binary_with_node(port, str) do
    str = String.replace(str, "'", "\'")
    repl_eval(port, "LZString.compressToUint8Array('#{str}').join(',')")
    |> String.strip(?') #'
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
    |> :erlang.list_to_binary
  end

  def lz_string_node_port do
    port = Port.open({:spawn, "node -i"}, [:binary])
    repl_eval(port, "LZString = require('lz-string')")
    port
  end

  defp repl_eval(port, str) do
    Port.command(port, str)
    Port.command(port, "\n")
    wait_for_result(port)
  end

  defp wait_for_result(port) do
    receive do
      {^port, {:data, "> "}} -> wait_for_result(port)
      {^port, {:data, "> " <> rest}} -> rest
      {^port, {:data, result}} -> result |> String.replace_suffix("> ", "")
    end |> String.strip
  end

end


ExUnit.start()
