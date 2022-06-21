defmodule LzString.Mixfile do
  use Mix.Project

  @version "0.0.8"

  def project do
    [
      app: :lz_string,
      version: @version,
      elixir: "~> 1.2",
      package: package(),
      docs: docs(),
      deps: deps(),
      description: "Elixir implementation of pieroxy's lz-string compression algorithm."
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    []
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps() do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Michael Shapiro"],
      licenses: ["MIT"],
      links: %{GitHub: "https://github.com/koudelka/elixir-lz-string"}
    ]
  end

  defp docs do
    [extras: ["README.md"],
     source_url: "https://github.com/koudelka/elixir-lz-string",
     source_ref: @version,
     assets: "assets",
     main: "readme"]
  end
end
