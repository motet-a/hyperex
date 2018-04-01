defmodule Hyperex.MixProject do
  use Mix.Project

  def project do
    [
      app: :hyperex,
      version: "0.1.0",
      elixir: "~> 1.6",
      deps: deps(),
      description: "A macro-powered HTML renderer"
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.5"},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:credo, "~> 0.9.0-rc1", only: [:dev, :test], runtime: false}
    ]
  end
end
