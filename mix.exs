defmodule ShEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :shex,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
#      {:rdf, "~> 0.6.1"},
      {:rdf, path: "../rdf"},
      {:flow, "~> 0.14"},
      {:jason, "~> 1.1"},
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
end
