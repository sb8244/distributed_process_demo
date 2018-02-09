defmodule DistributedProcess.Worker do
  use GenServer

  def start_link(id) do
    GenServer.start_link(__MODULE__, [], name: {:via, Registry, {get_registry_name(), id}})
  end

  def get_registry_name, do: Module.concat([__MODULE__, Registry])

  def init([]) do
    Process.send_after(self(), :self_terminate, 5000)
    {:ok, %{}}
  end

  def handle_call(:request, _from, state = %{value: value}) do
    IO.puts("Cached value returned #{inspect(value)}")
    {:reply, value, state}
  end

  def handle_call(:request, _from, state) do
    value = {Enum.random(1..1_000), Node.self()}
    IO.puts("Request made for #{inspect(value)}")
    {:reply, value, Map.put(state, :value, value)}
  end

  def handle_info(:self_terminate, _state) do
    DynamicSupervisor.terminate_child(DistributedProcess.Supervisor, self())
  end
end
