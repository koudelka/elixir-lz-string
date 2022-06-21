defmodule LZString.Base64 do
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
  |> String.to_charlist()
  |> Enum.with_index()
  |> Enum.each(fn {c, i} ->
    def base64_to_bitstring(unquote(c)), do: <<unquote(i)::size(6)>>
  end)

  defmacro __using__(_env) do
    quote do
      @doc ~S"""
      Compresses the given string and base64 encodes it.

          iex> LZString.compress_base64("hello, i am a 猫")
          "BYUwNmD2A0AECWsCGBbZtDUzkAA="
      """
      def compress_base64(str) do
        str |> compress |> Base.encode64()
      end

      @doc ~S"""
      Decompresses the given string after decoding lz-string's non-standard base64.

          iex> LZString.decompress_base64("BYUwNmD2A0AECWsCGBbZtDUzkA==")
          "hello, i am a 猫"
      """
      def decompress_base64(str) do
        str |> decode_base64 |> decompress
      end

      @doc ~S"""
      Decodes the given "base64" string, giving a naked lz-string bitstring.

      iex> LZString.decode_base64("BYUwNmD2A0AECWsCGBbZtDUzkA==")
      <<5, 133, 48, 54, 96, 246, 3, 64, 4, 9, 107, 2, 24, 22, 217, 180, 53, 51, 144, 0, 0>>
      """
      def decode_base64(str) do
        for <<c::utf8 <- str>>, into: <<>> do
          LZString.Base64.base64_to_bitstring(c)
        end
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
      Decompresses the given "uri encoded" base64 compressed string.

      iex> LZString.decompress_uri_encoded("BYUwNmD2A0AECWsCGBbZtDUzkAA$")
      "hello, i am a 猫"
      """
      def decompress_uri_encoded(str) do
        str
        |> String.replace("-", "/")
        |> String.replace("$", "=")
        |> decompress_base64
      end

      @doc ~S"""
      Decodes the given "uri encoded" base64 string, giving a naked lz-string bitstring.

      iex> LZString.decode_uri_encoded("BYUwNmD2A0AECWsCGBbZtDUzkA$$")
      <<5, 133, 48, 54, 96, 246, 3, 64, 4, 9, 107, 2, 24, 22, 217, 180, 53, 51, 144, 0, 0>>
      """
      def decode_uri_encoded(str) do
        str
        |> String.replace("-", "/")
        |> String.replace("$", "=")
        |> decode_base64
      end
    end
  end
end
