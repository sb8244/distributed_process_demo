defmodule DistributedProcess.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Registry, [keys: :unique, name: DistributedProcess.Worker.get_registry_name()]},
      {DistributedProcess.Supervisor, []}
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
