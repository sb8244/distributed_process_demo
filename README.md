# DistributedProcess Demo

This repo is a small demo of creating a choke point across a cluster of Elixir Nodes.
This was created for a blog post demonstrating the technique. Let's dive into the
workers and use cases.

## How it works

Elixir has the ability to connect to other nodes that are accessible on the network. We
can use this to spawn several local nodes that simulate a networked environment. The
`DistributedProcess.connect()` function iterates on up to 5 known node names and connects
to them. This is a quick hack to get them connected.

The application creates two different top level supervisors, a `Registry` which allows
unique storage of processes (unique by ID here) and a `DistributedProcess.Supervisor`.

The `DistributedProcess.Supervisor` does the majority of the work for distributing our
process across the cluster. It accepts an `id` into the `get_worker/1` function, and
uses a modulo operator on the number of nodes to determine which node will be the lucky
receiver of this request. The size of a node is fairly consistent in practice, so this
seems acceptable for starters.

When the right node is chosen, the `DynamicSupervisor.start_child` call creates an instance
of a `DistributedProcess.Worker` on the local or remote chosen node. This Worker is setup to
be unique based on the ID. This is really helpful as it allows future calls to the same ID
to return the same process.

Once a local or remote pid is returned from the DynamicSupervisor, that pid has a `call` request
execute against it. `call` will return an answer synchronously, which is great for the purposes
of this demo.

In the `DistributedProcess.Worker`, the first thing is does is actually tell itself to be destroyed
in 5 seconds. This is to make the demo interesting, but also simulates the use case of a short
lived cache.

The `handle_call(:request)` function in the worker does 2 different things, for 2 different
function heads. The first is if there is a value in the local state. Then it is simply
returned as is. The second is if there is no value in the local state. A random 1-1000
integer is selected and placed in the state, along with the node name. This allows us to see
that the data is in fact changing every 5 seconds, and where it came from.

All of this is packaged up into 2 top level functions that are called: `DistributedProcess.connect()`
and `DistributedProcess.request(id)`.

## Use Case

It may be desirable to have a single choke point across a cluster to handle a single
type of request. For instance, maybe a certain tenant should only execute on a single
server. This ensures that the requests for that tenant are serial (non-parallel).

My use case is to cache requests to a certain resource/id pair for 30-60 seconds.

## Gotchas

If the `GenServer.cast` fails to a remote node, then the request should be re-tried
on the local node to ensure that a request doesn't fail unnecessarily. I think that
the logic would over-complicate this demo.

## Demo

1. `mix deps.get`
2. `mix compile`
3. Run the following in 2 consoles

```
elixir --name 2@127.0.0.1 -S mix run --no-halt
elixir --name 3@127.0.0.1 -S mix run --no-halt
```

4. In a 4th console, run `iex --name 1@127.0.0.1 -S mix`
5. In the 4th console, play with commands like:

```
DistributedProcess.connect() # always required

DistributedProcess.request(1)
DistributedProcess.request(2)
DistributedProcess.request(3)
DistributedProcess.request(4) # cycle starts again, this will be a different ID than request (1)
DistributedProcess.request(1)
DistributedProcess.request(2)
DistributedProcess.request(3)
DistributedProcess.request(4) # cycle starts again

# Wait 5 seconds and do it again
```
