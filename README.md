# LZString

An Elixir implementation of [pieroxy/lz-string](https://github.com/pieroxy/lz-string), an LZ-based compression algorithm.

```elixir
iex> LZString.compress("hello, i am a 猫")
<<5, 133, 48, 54, 96, 246, 3, 64, 4, 9, 107, 2, 24, 22, 217, 180, 53, 51, 144, 0>>

iex> LZString.decompress(<<5, 133, 48, 54, 96, 246, 3, 64, 4, 9, 107, 2, 24, 22, 217, 180, 53, 51, 144, 0>>)
"hello, i am a 猫"

iex> LZString.compress_base64("hello, i am a 猫")
"BYUwNmD2A0AECWsCGBbZtDUzkAA="

iex> LZString.decompress_base64("BYUwNmD2A0AECWsCGBbZtDUzkA==")
"hello, i am a 猫"
```

## Installation

Add lz_string to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:lz_string, "~> 0.0.1"}]
end
```

## Running Tests
The tests compare LZString's output against that produced by the JS reference implementation (by way of a janky node.js `Port`). You'll need to install the node module in the root directory of the project beforehand:

```
$ npm install lz-string
```

Depending on how the port output is flushed, you'll once in a while get an error that complains about something like `:erlang.binary_to_integer("64'\n>")`, those are safe to ignore, and you can re-run the tests to try again. I'll gladly accept a PR to switch to https://github.com/awetzel/node_erlastic <3.

## Base64
The Base64 that the reference library produces is invalid, but we can still use it as the end-of-message indication is a dictionary marker rather than the actual end-of-input, so it may be academic. This library will properly decompress the invalid base64, and produce valid base64 output during compression.
