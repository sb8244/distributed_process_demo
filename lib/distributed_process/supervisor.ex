defmodule DistributedProcess.Supervisor do
  use DynamicSupervisor

  alias DistributedProcess.Worker

  def get_worker(id) do
    node = determine_node(id)
    # starts the child on the remote or local node
    DynamicSupervisor.start_child({__MODULE__, node}, {Worker, [id]})
    |> case do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
      _ -> :error
    end
  end

  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp determine_node(i) do
    # Take into account the remote + local nodes
    node_count = Node.list() |> length() |> Kernel.+(1)

    available_nodes()
    |> Enum.at(rem(i, node_count))
  end

  defp available_nodes() do
    [Node.self() | Node.list()]
  end
end
