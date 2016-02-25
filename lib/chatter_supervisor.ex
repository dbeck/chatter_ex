defmodule GroupManager.Chatter do

  use Supervisor
  require Logger
  require GroupManager.Data.Message
  require GroupManager.Data.WorldClock
  require GroupManager.Data.TimedSet
  require GroupManager.Chatter.Gossip
  require GroupManager
  require Common.BroadcastID
  require Common.NetID
  alias GroupManager.Chatter.OutgoingSupervisor
  alias GroupManager.Chatter.MulticastHandler
  alias GroupManager.Chatter.PeerDB
  alias GroupManager.Chatter.Gossip
  alias GroupManager.Data.Message
  alias Common.NetID

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
    own_id    = local_netid()
    multi_id  = multicast_netid()

    opts = [port: NetID.port(own_id)]

    listener_spec = :ranch.child_spec(
      :"GroupManager.Chatter.IncomingHandler",
      100,
      :ranch_tcp,
      opts,
      GroupManager.Chatter.IncomingHandler,
      [own_id: own_id, key: group_manager_key]
    )

    multicast_args = [
      own_id:          own_id,
      multicast_id:    multi_id,
      multicast_ttl:   multicast_ttl,
      key:             group_manager_key
    ]

    children = [
      worker(PeerDB, [[], [name: PeerDB.id_atom()]]),
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

  @spec broadcast(list(NetID.t), Message.t) :: :ok
  def broadcast(distribution_list, msg)
  when is_list(distribution_list) and Message.is_valid(msg)
  do
    :ok = NetID.validate_list(distribution_list)
    own_id = local_netid()
    {:ok, seqno} = PeerDB.inc_broadcast_seqno(PeerDB.locate!, own_id)
    {:ok, seen_ids} = PeerDB.get_seen_id_list_(own_id)

    gossip = Gossip.new(own_id, seqno, msg)
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
    :ok = OutgoingSupervisor.broadcast(gossip, group_manager_key)
  end

  def locate, do: Process.whereis(id_atom())

  def locate! do
    case Process.whereis(id_atom()) do
      pid when is_pid(pid) ->
        pid
    end
  end

  def id_atom, do: __MODULE__

  def get_local_ip
  do
    {:ok, list} = :inet.getif
    [{ip, _broadcast, _netmask}] = list
    |> Enum.filter( fn({_ip, bcast, _nm}) -> bcast != :undefined end)
    |> Enum.take(1)
    ip
  end

  def local_netid
  do
    # try to figure our local IP if not given
    case Application.fetch_env(:group_manager, :my_addr) do
      {:ok, nil} ->
        my_addr = get_local_ip()
      {:ok, my_addr_str} ->
        {:ok, my_addr} = my_addr_str |> String.to_char_list |> :inet_parse.address
      _ ->
        my_addr = get_local_ip()
    end

    my_port = case Application.fetch_env(:group_manager, :my_port)
    do
      {:ok, val} ->
        {my_port, ""} = val |> Integer.parse
        my_port
      :error ->
        Logger.info "no my_port config value found for group_manager Application [default: 29999]"
        29999
    end
    NetID.new(my_addr, my_port)
  end

  def multicast_netid
  do
    mcast_addr_str = case Application.fetch_env(:group_manager, :multicast_addr)
    do
      {:ok, val} ->
        val
      :error ->
        Logger.info "no multicast_addr config value found for group_manager Application [default: 224.1.1.1]"
        "224.1.1.1"
    end

    mcast_port_str = case Application.fetch_env(:group_manager, :multicast_port)
    do
      {:ok, val} ->
        val
      :error ->
        Logger.info "no multicast_port config value found for group_manager Application [default: 29999]"
        "29999"
    end

    {:ok, multicast_addr} = mcast_addr_str |> String.to_char_list |> :inet_parse.address
    {multicast_port, ""}  = mcast_port_str |> Integer.parse

    NetID.new(multicast_addr, multicast_port)
  end

  def multicast_ttl
  do
    case Application.fetch_env(:group_manager, :multicast_ttl)
    do
      {:ok, mcast_ttl_str} ->
        {multicast_ttl, ""}   = mcast_ttl_str  |> Integer.parse
        multicast_ttl
      :error ->
        Logger.info "no multicast_ttl config value found for group_manager Application [default: 4]"
        4
    end
  end

  def group_manager_key
  do
    case Application.fetch_env(:group_manager, :key)
    do
      {:ok, key} when is_binary(key) and byte_size(key) == 32->
        key

      :error ->
        Logger.error "no 'key' config value found for group_manager Application"
        "01234567890123456789012345678901"

      {:ok, key} ->
        Logger.error "'key' has to be 32 bytes long for group_manager Application"
        << retval :: binary-size(32), _rest :: binary  >> = key <> "01234567890123456789012345678901"
        retval
    end
  end
end
