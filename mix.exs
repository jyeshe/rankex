defmodule Rankex.MixProject do
  use Mix.Project

  @version "0.1.0"

  @description """
  Ranking/leaderboard library based on ETS ordered set for Elixir.
  """

  def project do
    [
      app: :rankex,
      version: @version,
      description: @description,
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      source_url: "https://github.com/jyeshe/rankex",
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE*"],
      maintainers: ["Rogerio Pontual"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/jyeshe/rankex"}
    ]
  end

  defp deps do
    [
    ]
  end
end
