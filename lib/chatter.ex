defmodule Chatter do

  @moduledoc """
  `Chatter` allows broadcasting information between a set of nodes. Nodes are identified by
  the `Chatter.NetID` record, which contains an IPv4 address and a port.


  TODO
  """

  use Application
  require Logger
  require Chatter.NetID
  require Chatter.BroadcastID
  require Chatter.Gossip
  alias Chatter.NetID
  alias Chatter.BroadcastID
  alias Chatter.MulticastHandler
  alias Chatter.OutgoingSupervisor
  alias Chatter.PeerDB
  alias Chatter.SerializerDB
  alias Chatter.Gossip

  def start(_type, args)
  do
    :random.seed(:os.timestamp)
    Chatter.Supervisor.start_link(args)
  end

  @doc """
  TODO
  """
  @spec broadcast(Gossip.t) :: :ok
  def broadcast(gossip)
  when Gossip.is_valid(gossip)
  do
    broadcast(Gossip.distribution_list(gossip), Gossip.payload(gossip))
  end

  @doc """
  TODO
  """
  @spec broadcast(list(NetID.t), tuple) :: :ok
  def broadcast(distribution_list, tup)
  when is_list(distribution_list) and
       is_tuple(tup) and
       tuple_size(tup) > 1
  do
    :ok = NetID.validate_list(distribution_list)

    # verify that the payload serializer has already registered
    {:ok, _handler} = SerializerDB.get_(tup)

    own_id = Chatter.local_netid
    {:ok, seqno} = PeerDB.inc_broadcast_seqno(PeerDB.locate!, own_id)
    {:ok, seen_ids} = PeerDB.get_seen_id_list_(own_id)

    # build a reverse seen ID list of who has seen us
    # TODO : optimize this?
    rev_seen_ids = distribution_list |> Enum.reduce([], fn(x, acc) ->
      case PeerDB.get_seen_id_list_(x)
      do
        {:ok, []} -> acc
        {:ok, lst} ->
          if Enum.any?(lst, fn(t) -> BroadcastID.origin(t) == own_id end)
          do
            [x|acc]
          else
            acc
          end
        _ -> acc
      end
    end)

    gossip = Gossip.new(own_id, seqno, tup)
    |> Gossip.distribution_list(distribution_list)
    |> Gossip.seen_ids(seen_ids)

    ## Logger.debug "multicasting [#{inspect gossip}]"

    # multicast first
    :ok = MulticastHandler.send(MulticastHandler.locate!, gossip)

    # the remaining list must be contacted directly
    gossip =
      Gossip.remove_from_distribution_list(gossip, rev_seen_ids)

    # add 1 random element to the distribution list from the original
    # distribution list
    gossip =
      Gossip.add_to_distribution_list(gossip,
                                      Enum.take_random(distribution_list, 1))

    # outgoing handler uses its already open channels and returns the gossip
    # what couldn't be delivered
    :ok = OutgoingSupervisor.broadcast(gossip, Chatter.group_manager_key)
  end

  @doc """
  Return the list of peers `Chatter` has ever seen. The list omits the local
  `NetID` even though PeerDB has an entry for it.

  ```
  iex(1)> Chatter.peers
  [{:net_id, {192, 168, 1, 100}, 29999}]

  ```
  """
  def peers()
  do
    my_id = local_netid
    PeerDB.get_peers_() |> Enum.filter(fn(x) -> x != my_id end)
  end

  @doc """
  Returns the local IPv4 address in the form of a tuple.

  ```
    iex(1)> Chatter.get_local_ip
    {192, 168, 1, 100}
  ```
  """
  def get_local_ip
  do
    {:ok, list} = :inet.getif
    [{ip, _broadcast, _netmask}] = list
    |> Enum.filter( fn({_ip, bcast, _nm}) -> bcast != :undefined end)
    |> Enum.take(1)
    ip
  end

  @doc """
  Returns the local node's `NetID`. This function uses the following configuration values:

  - :chatter / :my_addr
  - :chatter / :my_port

  If none of these are available, the local IPv4 address will be determined by
  the `Chatter.get_local_ip` function and the port will be defaulted to `29999`.

  ```
  iex(1)> Chatter.local_netid
  {:net_id, {192, 168, 1, 100}, 29998}
  ```
  """
  def local_netid
  do
    # try to figure our local IP if not given
    case Application.fetch_env(:chatter, :my_addr) do
      {:ok, nil} ->
        my_addr = get_local_ip()
      {:ok, my_addr_str} ->
        {:ok, my_addr} = my_addr_str |> String.to_char_list |> :inet_parse.address
      _ ->
        my_addr = get_local_ip()
    end

    my_port = case Application.fetch_env(:chatter, :my_port)
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

  @doc """
  Returns the local node's UDP multicast `NetID`. This function uses the following configuration values:

  - :chatter / :multicast_addr
  - :chatter / :multicast_port

  If none of these are available, the UDP multicast address will be `224.1.1.1` by default
  and the port will be defaulted to `29999`.

  ```
  iex(1)> Chatter.multicast_netid
  {:net_id, {224, 1, 1, 1}, 29999}
  ```
  """
  def multicast_netid
  do
    mcast_addr_str = case Application.fetch_env(:chatter, :multicast_addr)
    do
      {:ok, val} ->
        val
      :error ->
        Logger.info "no multicast_addr config value found for group_manager Application [default: 224.1.1.1]"
        "224.1.1.1"
    end

    mcast_port_str = case Application.fetch_env(:chatter, :multicast_port)
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

  @doc """
  Returns the local node's UDP multicast TTL value. This function uses the following configuration value:

  - :chatter / :multicast_ttl

  If no confifuration value is available, the default is `4`.

  ```
  iex(1)> Chatter.multicast_ttl
  4

  ```
  """
  def multicast_ttl
  do
    case Application.fetch_env(:chatter, :multicast_ttl)
    do
      {:ok, mcast_ttl_str} ->
        {multicast_ttl, ""}   = mcast_ttl_str  |> Integer.parse
        multicast_ttl
      :error ->
        Logger.info "no multicast_ttl config value found for group_manager Application [default: 4]"
        4
    end
  end

  @doc """
  Returns the local node's encryption key. This function uses the following configuration value:

  - :chatter / :key

  The encryption key needs to be 32 characters long. The longer key will be chopped, the shorter key
  will be concatenated with `01234567890123456789012345678901` and then chopped to 32 characters.
  """
  def group_manager_key
  do
    case Application.fetch_env(:chatter, :key)
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
