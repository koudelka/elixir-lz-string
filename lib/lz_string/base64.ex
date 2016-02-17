defmodule LZString.Base64 do

  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
  |> String.to_char_list
  |> Enum.with_index
  |> Enum.each(fn {c, i} ->
    def base64_to_bitstring(unquote(c)), do: << unquote(i) :: size(6) >>
  end)

  defmacro __using__(_env) do
    quote do
      @doc ~S"""
      Compresses the given string and base64 encodes it.

          iex> LZString.compress_base64("hello, i am a 猫")
          "BYUwNmD2A0AECWsCGBbZtDUzkAA="
      """
      def compress_base64(str) do
        str |> compress |> Base.encode64
      end

      @doc ~S"""
      Decompresses the given binary after decoding lz-string's non-standard base64.

          iex> LZString.decompress_base64("BYUwNmD2A0AECWsCGBbZtDUzkA==")
          "hello, i am a 猫"
      """
      def decompress_base64(str) do
        str |> do_decompress_base64 |> decompress
      end

      defp do_decompress_base64(""), do: ""
      defp do_decompress_base64(<< c :: utf8 >> <> rest) do
        << LZString.Base64.base64_to_bitstring(c) :: bitstring, do_decompress_base64(rest) :: bitstring >>
      end

      @doc ~S"""
      Compresses the given string and base64 encodes it, substituting uri-unsafe characters.

      iex> LZString.compress_uri_encoded("hello, i am a 猫")
      "BYUwNmD2A0AECWsCGBbZtDUzkAA$"
      """
      def compress_uri_encoded(str) do
        str
        |> compress_base64
        |> String.replace("/", "-")
        |> String.replace("=", "$")
      end

      @doc ~S"""
      Decompresses the given "uri encoded" base64 compressed binary.

      iex> LZString.decompress_uri_encoded("BYUwNmD2A0AECWsCGBbZtDUzkAA$")
      "hello, i am a 猫"
      """
      def decompress_uri_encoded(str) do
        str
        |> String.replace("-", "/")
        |> String.replace("$", "=")
        |> decompress_base64
      end

    end
  end
end
