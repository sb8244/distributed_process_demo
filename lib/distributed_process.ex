defmodule DistributedProcess do
  alias DistributedProcess.Supervisor

  def connect() do
    (1..5)
    |> Enum.map(fn i ->
      node = :"#{i}@127.0.0.1"
      {node, Node.connect(node)}
    end)
  end

  def request(id) do
    Supervisor.get_worker(id)
    |> GenServer.call(:request)
  end
end
