defmodule Chatter.Supervisor do

  use Supervisor
  require Logger
  require Chatter.Gossip
  require Chatter.BroadcastID
  require Chatter.NetID
  alias Chatter.OutgoingSupervisor
  alias Chatter.MulticastHandler
  alias Chatter.PeerDB
  alias Chatter.SerializerDB
  alias Chatter.Gossip
  alias Chatter.NetID

  def start_link(opts \\ [])
  do
    case opts do
      [name: _name] ->
        Supervisor.start_link(__MODULE__, :no_args, opts)
      _ ->
        Supervisor.start_link(__MODULE__, :no_args, [name: id_atom()] ++ opts)
    end
  end

  def init(:no_args)
  do
    own_id             = Chatter.local_netid()
    multi_id           = Chatter.multicast_netid()
    group_manager_key  = Chatter.group_manager_key

    opts = [port: NetID.port(own_id)]

    listener_spec = :ranch.child_spec(
      :"Chatter.IncomingHandler",
      100,
      :ranch_tcp,
      opts,
      Chatter.IncomingHandler,
      [own_id: own_id, key: group_manager_key]
    )

    multicast_args = [
      own_id:          own_id,
      multicast_id:    multi_id,
      multicast_ttl:   Chatter.multicast_ttl,
      key:             Chatter.group_manager_key
    ]

    children = [
      worker(PeerDB, [[], [name: PeerDB.id_atom()]]),
      worker(SerializerDB, [[], [name: SerializerDB.id_atom()]]),
      listener_spec,
      supervisor(OutgoingSupervisor, [[], [name: OutgoingSupervisor.id_atom()]]),
      worker(MulticastHandler, [multicast_args, [name: MulticastHandler.id_atom()]])
    ]

    {:ok, _pid} = supervise(children, strategy: :one_for_one)
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
