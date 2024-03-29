defmodule LZString do
  use LZString.Base64

  @compress_dict %{
    size_8: 0,
    size_16: 1,
    eof: 2
  }

  @decompress_dict Enum.into(@compress_dict, %{}, fn {k, v} -> {v, k} end)

  @size_8 @compress_dict[:size_8]
  @size_16 @compress_dict[:size_16]
  @eof @compress_dict[:eof]

  @doc ~S"""
    Compresses the given String with the lz-string algorithm.

       iex> LZString.compress("hello, i am a 猫")
       <<5, 133, 48, 54, 96, 246, 3, 64, 4, 9, 107, 2, 24, 22, 217, 180, 53, 51, 144, 0>>
  """

  @spec compress(String.t()) :: binary
  def compress(""), do: ""

  def compress(str) do
    output = compress("", str, @compress_dict) |> :erlang.list_to_bitstring()

    # the js implementation incorrectly adds padding when none is needed, so we do too.
    padding_bits = 16 - (output |> bit_size |> rem(16))
    # padding_bits =
    #   case 16 - (output |> bit_size |> rem(16)) do
    #     16 -> 0
    #     n -> n
    #   end
    <<output::bitstring, 0::size(padding_bits)>>
  end

  def compress(w, <<c::utf8>> <> rest, dict) do
    c = <<c::utf8>>

    char_just_added = !Map.has_key?(dict, c)

    dict =
      if char_just_added do
        Map.put(dict, c, {:first_time, map_size(dict)})
      else
        dict
      end

    wc = w <> c

    if Map.has_key?(dict, wc) do
      compress(wc, rest, dict)
    else
      {dict, output} = w_output(w, dict, char_just_added)
      dict = Map.put(dict, wc, map_size(dict))
      [output | compress(c, rest, dict)]
    end
  end

  def compress(w, "", dict) do
    size = num_bits(map_size(dict) - 1)
    {_dict, output} = w_output(w, dict, false)
    [output, reverse(<<dict[:eof]::size(size)>>)]
  end

  defp w_output([], _dict, _char_just_added), do: <<>>

  defp w_output(w, dict, char_just_added) do
    case Map.fetch(dict, w) do
      {:ok, {:first_time, dict_index}} ->
        dict = Map.put(dict, w, dict_index)
        marker_size = num_bits(dict_index)
        <<char_val::utf8>> = w

        {size_marker, char_size} =
          if num_bits(char_val) <= 8 do
            {dict[:size_8], 8}
          else
            {dict[:size_16], 16}
          end

        size_marker_bits = reverse(<<size_marker::size(marker_size)>>)
        char_bits = reverse(<<char_val::size(char_size)>>)
        {dict, <<size_marker_bits::bitstring, char_bits::bitstring>>}

      {:ok, dict_index} ->
        map_size = map_size(dict) - 1
        # a char just being added to the dict may cause us to add an extra bit
        # to the dict_index output where one isn't strictly needed yet
        map_size =
          if char_just_added do
            map_size - 1
          else
            map_size
          end

        size = num_bits(map_size)
        {dict, reverse(<<dict_index::size(size)>>)}
    end
  end

  @doc ~S"""
  Decompresses the given binary with the lz-string algorithm.

    iex> LZString.decompress(<<5, 133, 48, 54, 96, 246, 3, 64, 4, 9, 107, 2, 24, 22, 217, 180, 53, 51, 144, 0>>)
    "hello, i am a 猫"
  """

  @spec decompress(binary) :: String.t()
  def decompress(""), do: ""

  def decompress(str) do
    {:char, c, rest, dict} = decode_next_segment(str, @decompress_dict)
    decompress(c, rest, dict) |> :erlang.list_to_binary() |> :unicode.characters_to_binary(:utf16)
  end

  def decompress(w, str, dict) do
    case decode_next_segment(str, dict) do
      {:char, c, rest, dict} ->
        dict = Map.put(dict, map_size(dict), w <> c)
        [w | decompress(c, rest, dict)]

      {:seq, seq, rest} ->
        c =
          case Map.fetch(dict, seq) do
            {:ok, decompressed} ->
              decompressed

            :error ->
              unless map_size(dict) == seq, do: raise("unknown sequence index #{seq}")
              w <> first_utf16(w)
          end

        dict = Map.put(dict, map_size(dict), w <> first_utf16(c))
        [w | decompress(c, rest, dict)]

      :eof ->
        [w]
    end
  end

  defp decode_next_segment(str, dict) do
    size = dict |> map_size |> num_bits
    <<dict_entry::size(size), rest::bitstring>> = str
    # dict_entry is in LSB format, bring it back to MSB
    <<dict_entry::size(size)>> = reverse(<<dict_entry::size(size)>>)

    case dict_entry do
      @size_8 ->
        <<c::size(8), rest::bitstring>> = rest
        <<c::size(8)>> = reverse(<<c::size(8)>>)
        char = <<c::utf16>>
        dict = Map.put(dict, map_size(dict), char)
        {:char, char, rest, dict}

      @size_16 ->
        <<c::size(16), rest::bitstring>> = rest
        <<c::size(16)>> = reverse(<<c::size(16)>>)
        char = <<c::16>>
        dict = Map.put(dict, map_size(dict), char)
        {:char, char, rest, dict}

      @eof ->
        :eof

      index ->
        {:seq, index, rest}
    end
  end

  defp first_utf16(<<c::16>> <> _) do
    <<c::16>>
  end

  defp num_bits(0), do: 1

  defp num_bits(int) do
    int
    |> :math.log2()
    |> trunc
    |> Kernel.+(1)
  end

  # http://erlang.org/euc/07/papers/1700Gustafsson.pdf
  defp reverse(<<>>), do: <<>>

  defp reverse(<<bit::size(1), rest::bitstring>>) do
    <<reverse(rest)::bitstring, bit::size(1)>>
  end

  def debug(bitstring) do
    for <<bit::size(1) <- bitstring>>, do: bit
  end
end
