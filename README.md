# New Relic Oban

[![Hex.pm Version](https://img.shields.io/hexpm/v/new_relic_oban.svg)](https://hex.pm/packages/new_relic_oban)

This package adds `Oban` specific instrumentation on top of the `new_relic_agent` package. You may use all the built-in capabilities of the New Relic Agent!

Check out the agent for more:

* https://github.com/newrelic/elixir_agent
* https://hexdocs.pm/new_relic_agent

## Installation

Install the [Hex package](https://hex.pm/packages/new_relic_oban)

```elixir
defp deps do
  [
    {:oban, "~> 2.1"},
    {:new_relic_oban, "~> 0.1"}
  ]
end
```

## Configuration

* You must configure `new_relic_agent` to authenticate to New Relic. Please see: https://github.com/newrelic/elixir_agent/#configuration

## Instrumentation

1) Add the Oban Genserver to your supervisor tree

```elixir
defmodule MyApp.Application do
  @moduledoc false

  use Application
  def start(_type, args) do

    extra_children = Keyword.get(args, :extra_children, [])

    # List all child processes to be supervised
    children = [
      MyApp.Repo,
      NewRelicOban.Telemetry.Oban,
      {Oban, Application.get_env(:my_app, Oban)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Broker.Supervisor]
    Supervisor.start_link(children ++ extra_children, opts)
  end
end
```
