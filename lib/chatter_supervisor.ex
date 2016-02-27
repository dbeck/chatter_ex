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

  @spec broadcast(Gossip.t) :: :ok
  def broadcast(gossip)
  when Gossip.is_valid(gossip)
  do
    broadcast(Gossip.distribution_list(gossip), Gossip.payload(gossip))
  end

  @spec broadcast(list(NetID.t), tuple) :: :ok
  def broadcast(distribution_list, tup)
  when is_list(distribution_list) and
       is_tuple(tup) and
       tuple_size(tup) > 1
  do
    :ok = NetID.validate_list(distribution_list)
    own_id = Chatter.local_netid
    {:ok, seqno} = PeerDB.inc_broadcast_seqno(PeerDB.locate!, own_id)
    {:ok, seen_ids} = PeerDB.get_seen_id_list_(own_id)

    gossip = Gossip.new(own_id, seqno, tup)
    |> Gossip.distribution_list(distribution_list)
    |> Gossip.seen_ids(seen_ids)

    ## Logger.debug "multicasting [#{inspect gossip}]"

    # multicast first
    :ok = MulticastHandler.send(MulticastHandler.locate!, gossip)

    # the remaining list must be contacted directly
    gossip =
      Gossip.remove_from_distribution_list(gossip, Gossip.seen_netids(gossip))

    # add 1 random elements to the distribution list from the original
    # distribution list
    gossip =
      Gossip.add_to_distribution_list(gossip,
                                      Enum.take_random(distribution_list, 1))

    # outgoing handler uses its already open channels and returns the gossip
    # what couldn't be delivered
    :ok = OutgoingSupervisor.broadcast(gossip, Chatter.group_manager_key)
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
