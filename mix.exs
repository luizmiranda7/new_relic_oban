defmodule NewRelicOban.MixProject do
  use Mix.Project

  def project do
    [
      app: :new_relic_oban,
      description: "New Relic Instrumentation for Oban",
      version: "0.0.2",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      name: "New Relic Oban",
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      maintainers: ["Luiz Miranda"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/luizmiranda7/new_relic_oban"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:new_relic_agent, "~> 1.19"},
      {:oban, "~> 2.1", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
