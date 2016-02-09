defmodule LZString do
  use LZString.Base64

  @compress_dict %{
    size_8:  0,
    size_16: 1,
    eof:     2
  }

  @decompress_dict Enum.into(@compress_dict, %{}, fn {k, v} -> {v, k} end)

  @size_8  @compress_dict[:size_8]
  @size_16 @compress_dict[:size_16]
  @eof     @compress_dict[:eof]



  @doc ~S"""
    Compresses the given String with the lz-string algorithm.

       iex> LZString.compress("hello, i am a 猫")
       <<5, 133, 48, 54, 96, 246, 3, 64, 4, 9, 107, 2, 24, 22, 217, 180, 53, 51, 144, 0>>
  """

  @spec compress(String.t) :: binary
  def compress(""), do: ""
  def compress(str) do
    output = compress("", str, @compress_dict) |> :erlang.list_to_bitstring

    # the js implementation incorrectly adds padding when none is needed, so we do too.
    padding_bits = 16 - (output |> bit_size |> rem(16))
    # padding_bits =
    #   case 16 - (output |> bit_size |> rem(16)) do
    #     16 -> 0
    #     n -> n
    #   end
    << output :: bitstring , 0 :: size(padding_bits) >>
  end

  def compress(w, << c :: utf8 >> <> rest, dict) do
    c = << c :: utf8 >>

    char_just_added = false
    if !Map.has_key?(dict, c) do
      char_just_added = true
      dict = Map.put(dict, c, {:first_time, map_size(dict)})
    end

    wc = w <> c
    if Map.has_key?(dict, wc) do
      w = wc
      compress(w, rest, dict)
    else
      {dict, output} = w_output(w, dict, char_just_added)
      dict = Map.put(dict, wc, map_size(dict))
      w = c
      [output | compress(w, rest, dict)]
    end
  end

  def compress(w, "", dict) do
    size = num_bits(map_size(dict) - 1)
    {_dict, output} = w_output(w, dict, false)
    [output, reverse(<< dict[:eof] :: size(size) >>)]
  end

  defp w_output([], _dict, _char_just_added), do: <<>>
  defp w_output(w, dict, char_just_added) do
    case Map.fetch(dict, w) do
      {:ok, {:first_time, dict_index}} ->
        dict = Map.put(dict, w, dict_index)
        marker_size = num_bits(dict_index)
        << char_val :: utf8 >> = w
        {size_marker, char_size} =
          if num_bits(char_val) <= 8 do
            {dict[:size_8], 8}
          else
            {dict[:size_16], 16}
          end
        size_marker_bits = reverse(<< size_marker :: size(marker_size) >>)
        char_bits = reverse(<< char_val :: size(char_size)>>)
        {dict, << size_marker_bits :: bitstring, char_bits :: bitstring >>}
      {:ok, dict_index} ->
        map_size = map_size(dict) - 1
        # a char just being added to the dict may cause us to add an extra bit
        # to the dict_index output where one isn't strictly needed yet
        if char_just_added do
          map_size = map_size - 1
        end
        size = num_bits(map_size)
        {dict, reverse(<< dict_index :: size(size) >>)}
    end
  end


  @doc ~S"""
  Decompresses the given binary with the lz-string algorithm.

    iex> LZString.decompress(<<5, 133, 48, 54, 96, 246, 3, 64, 4, 9, 107, 2, 24, 22, 217, 180, 53, 51, 144, 0>>)
    "hello, i am a 猫"
  """

  @spec decompress(binary) :: String.t
  def decompress(""), do: ""
  def decompress(str) do
    {:char, c, rest, dict} = decode_next_segment(str, @decompress_dict)
    decompress(c, rest, dict) |> :erlang.list_to_binary
  end

  def decompress(w, str, dict) do
    w_str = decompress_sequence(w, dict)
    case decode_next_segment(str, dict) do
      {:char, c, rest, dict} ->
        dict = Map.put(dict, map_size(dict), w_str <> String.first(c))
        [w_str | decompress(c, rest, dict)]
      {:seq, seq, rest} ->
        c = decompress_sequence(w_str, seq, dict)
        dict = Map.put(dict, map_size(dict), w_str <> String.first(c))
        [w_str | decompress(c, rest, dict)]
      :eof -> [w_str]
    end
  end

  def decompress_sequence(w, s, dict) do
    case Map.fetch(dict, s) do
      {:ok, seq} -> seq
      :error ->
        unless map_size(dict) == s, do: raise "unknown sequence index #{s}"
        w <> String.first(w)
    end
  end
  def decompress_sequence(s, _dict), do: s

  def decode_next_segment(str, dict) do
    size = dict |> map_size |> num_bits
    << dict_entry :: size(size), rest :: bitstring >> = str
    # dict_entry is in LSB format, bring it back to MSB
    << dict_entry :: size(size) >> = reverse(<< dict_entry :: size(size) >>)

    case dict_entry do
      @size_8 ->
        << c :: size(8), rest :: bitstring >> = rest
        << c :: size(8) >> = reverse(<< c :: size(8)>>)
        char = << c :: utf8 >>
        dict = Map.put(dict, map_size(dict), char)
        {:char, char, rest, dict}
      @size_16 ->
        << c :: size(16), rest :: bitstring >> = rest
        << c :: size(16) >> = reverse(<< c :: size(16)>>)
        char = << c :: utf8 >>
        dict = Map.put(dict, map_size(dict), char)
        {:char, char, rest, dict}
      @eof ->
        :eof
      sequence ->
        {:seq, sequence, rest}
    end
  end


  def num_bits(0), do: 1
  def num_bits(int) do
    int
    |> :math.log2
    |> trunc
    |> Kernel.+(1)
  end

  # http://erlang.org/euc/07/papers/1700Gustafsson.pdf
  def reverse(<<>>), do: <<>>
  def reverse(<< bit :: size(1), rest :: bitstring >>) do
    << reverse(rest) :: bitstring, bit :: size(1) >>
  end

  def debug(bitstring) do
    for << bit :: size(1) <- bitstring >>, do: bit
  end

end
