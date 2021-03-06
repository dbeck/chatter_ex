defmodule Chatter.OutgoingSupervisor do

  use Supervisor
  require Chatter.Gossip
  require Chatter.NetID
  require Chatter.BroadcastID
  alias Chatter.OutgoingHandler
  alias Chatter.Gossip
  alias Chatter.NetID
  alias Chatter.BroadcastID
  alias Chatter.Planner

  def start_link(args, opts \\ []) do
    case opts do
      [name: _name] ->
        Supervisor.start_link(__MODULE__, args, opts)
      _ ->
        Supervisor.start_link(__MODULE__, args, [name: __MODULE__] ++ opts)
    end
  end

  def init(_args) do
    children = [ supervisor(OutgoingHandler, [], restart: :temporary) ]
    supervise(children, strategy: :simple_one_for_one)
  end

  def broadcast(gossip, key)
  when Gossip.is_valid(gossip) and
       is_binary(key) and
       byte_size(key) == 32
  do
    Planner.plan(Gossip.distribution_list(gossip))
    |> Enum.each( fn(p) ->
      List.flatten(p)
      |> Enum.shuffle
      |> broadcast_to(gossip, key)
    end)
  end

  defp broadcast_to([], _gossip, _key), do: :ok

  defp broadcast_to(distribution_list, gossip, key)
  do
    [head|rest] = distribution_list
    own_id = Gossip.current_id(gossip) |> BroadcastID.origin
    case start_handler(locate!, [own_id: own_id, peer_id: head, key: key]) do
      {:ok, handler_pid} ->
        OutgoingHandler.send(handler_pid, gossip |> Gossip.distribution_list(rest))
      _ ->
        # use the next id in case of an error
        broadcast_to(rest, gossip, key)
    end
  end

  def start_handler(sup_pid, [own_id: own_id, peer_id: peer_id, key: key])
  when is_pid(sup_pid) and
       NetID.is_valid(peer_id) and
       NetID.is_valid(own_id)
  do
    case OutgoingHandler.locate(peer_id) do
      handler_pid when is_pid(handler_pid) ->
        {:ok, handler_pid}
      _ ->
        id = OutgoingHandler.id_atom(peer_id)
        Supervisor.start_child(sup_pid, [
          [own_id: own_id, peer_id: peer_id, key: key],
          [name: id]])
    end
  end

  def locate, do: Process.whereis(id_atom())

  def locate! do
    case Process.whereis(id_atom()) do
      pid when is_pid(pid) ->
        pid
    end
  end

  def id_atom, do: __MODULE__
end
