defmodule NewRelicOban.Telemetry.Oban do
  @moduledoc """
  Provides `Oban` instrumentation via `telemetry`.

  Oban pipelines are auto-discovered and instrumented.

  We automatically gather:

  * Transaction metrics and events
  * Transaction Traces

  ----

  To prevent reporting an individual transaction:

  ```elixir
  NewRelic.ignore_transaction()
  ```

  ----

  Inside a Transaction, the agent will track work across processes that are spawned and linked.
  You can signal to the agent not to track work done inside a spawned process, which will
  exclude it from the current Transaction.

  To exclude a process from the Transaction:

  ```elixir
  Task.async(fn ->
    NewRelic.exclude_from_transaction()
    Work.wont_be_tracked()
  end)
  ```
  """
  use GenServer

  alias NewRelic.Transaction

  @doc false
  def start_link(_) do
    config = %{
      handler_id: {:new_relic, :oban}
    }

    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @oban_start [:oban, :job, :start]
  @oban_stop [:oban, :job, :stop]
  @oban_exception [:oban, :job, :exception]

  @oban_events [
    @oban_start,
    @oban_stop,
    @oban_exception
  ]

  @doc false
  def init(config) do
    :telemetry.attach_many(
      config.handler_id,
      @oban_events,
      &__MODULE__.handle_event/4,
      config
    )

    Process.flag(:trap_exit, true)
    {:ok, config}
  end

  @doc false
  def terminate(_reason, %{handler_id: handler_id}) do
    :telemetry.detach(handler_id)
  end

  @doc false
  def handle_event(
        @oban_start,
        %{system_time: system_time},
        meta,
        _config
      ) do
    Transaction.Reporter.start_transaction(:other)

    add_start_attrs(meta, system_time)
  end

  def handle_event(
        @oban_stop,
        %{duration: duration} = meas,
        meta,
        _config
      ) do
    add_stop_attrs(meas, meta, duration)

    Transaction.Reporter.stop_transaction(:other)
  end

  def handle_event(
        @oban_exception,
        %{duration: duration} = meas,
        %{kind: kind} = meta,
        _config
      ) do
    add_stop_attrs(meas, meta, duration)
    {reason, stack} = reason_and_stack(meta)

    Transaction.Reporter.fail(%{kind: kind, reason: reason, stack: stack})
    Transaction.Reporter.stop_transaction(:other)
  end

  def handle_event(_event, _measurements, _meta, _config) do
    :ignore
  end

  defp add_start_attrs(meta, system_time) do
    name = "Oban/#{meta.job.worker}/perform"

    [
      pid: inspect(self()),
      system_time: system_time,
      state: meta.job.state,
      worker: name,
      queue: meta.job.queue,
      tags: meta.job.tags,
      attempt: meta.job.attempt,
      attempted_by: meta.job.attempted_by,
      max_attempts: meta.job.max_attempts,
      priority: meta.job.priority,
      name: name,
      other_transaction_name: name
    ]
    |> NewRelic.add_attributes()
  end

  @kb 1024
  defp add_stop_attrs(meas, meta, duration) do
    info = Process.info(self(), [:memory, :reductions])

    [
      duration: duration,
      queue_time: meas.queue_time,
      result: meta[:result],
      state: meta.job.state,
      memory_kb: info[:memory] / @kb,
      reductions: info[:reductions]
    ]
    |> NewRelic.add_attributes()
  end

  defp reason_and_stack(%{reason: %{__exception__: true} = reason, stacktrace: stack}) do
    {reason, stack}
  end

  defp reason_and_stack(%{reason: {{reason, stack}, _init_call}}) do
    {reason, stack}
  end

  defp reason_and_stack(%{reason: {reason, _init_call}}) do
    {reason, []}
  end

  defp reason_and_stack(unexpected_exception) do
    NewRelic.log(:debug, "unexpected_exception: #{inspect(unexpected_exception)}")
    {:unexpected_exception, []}
  end
end
