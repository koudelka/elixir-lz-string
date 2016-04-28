defmodule LzString.Mixfile do
  use Mix.Project

  def project do
    [app: :lz_string,
     version: "0.0.4",
     elixir: "~> 1.2",
     package: package,
     deps: deps(Mix.env),
     description: "Elixir implementation of pieroxy's lz-string compression algorithm."]
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
  defp deps(:test) do
    [
        {:parallel, github: "eproxus/parallel"}
    ]
  end

  defp deps(_) do
    []
  end

  defp package do
    [maintainers: ["Michael Shapiro"],
     licenses: ["MIT"],
     links: %{"GitHub": "https://github.com/koudelka/elixir-lz-string"}]
  end
end
