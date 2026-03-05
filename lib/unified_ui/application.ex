defmodule UnifiedUi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  @spec start(:normal | {:takeover, node()} | {:failover, node()}, term()) ::
          {:ok, pid()} | {:ok, pid(), term()} | {:error, term()}
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: UnifiedUi.AgentRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: UnifiedUi.AgentSupervisor}
    ]

    opts = [strategy: :one_for_one, name: UnifiedUi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  @spec stop(term()) :: :ok
  def stop(_state), do: :ok
end
