defmodule Hyperex.MixProject do
  use Mix.Project

  def project do
    [
      app: :hyperex,
      name: "Hyperex",
      package: package(),
      version: "0.1.0",
      elixir: "~> 1.6",
      deps: deps(),
      description: "A macro-powered HTML renderer",
      source_url: "https://github.com/motet-a/hyperex"
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.5"},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:credo, "~> 0.9.0-rc1", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      name: "hyperex",
      links: %{"GitHub" => "https://github.com/motet-a/hyperex"},
      licenses: ["Apache 2.0"],
      maintainers: ["Antoine Motet"],
      files: ["lib", "mix.exs", "README*", "LICENSE*"]
    ]
  end
end
