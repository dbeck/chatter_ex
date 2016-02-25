defmodule GroupManager.Chatter.MulticastHandler do

  use ExActor.GenServer
  require GroupManager.Chatter.Gossip
  require Common.BroadcastID
  require Common.NetID
  require Logger
  alias GroupManager.Chatter.Gossip
  alias GroupManager.Chatter.PeerDB
  alias GroupManager.Receiver
  alias Common.NetID
  alias Common.Serializer
  alias Common.BroadcastID

  defstart start_link([own_id:        own_id,
                       multicast_id:  multi_id,
                       multicast_ttl: ttl,
                       key: key],
                      opts),
    gen_server_opts: opts
  do
    my_addr         = NetID.ip(own_id)
    multicast_addr  = NetID.ip(multi_id)
    multicast_port  = NetID.port(multi_id)

    udp_options = [
      :binary,
      active:          10,
      add_membership:  { multicast_addr, my_addr },
      multicast_if:    my_addr,
      multicast_loop:  false,
      multicast_ttl:   ttl,
      reuseaddr:       true
    ]

    {:ok, socket} = :gen_udp.open( multicast_port, udp_options )
    initial_state([socket: socket,
                   own_id: own_id,
                   multicast_id: multi_id,
                   key: key])
  end

  @spec send(pid, Gossip.t) :: Gossip.t
  def send(pid, gossip)
  when is_pid(pid) and Gossip.is_valid(gossip)
  do
    GenServer.call(pid, {:send, gossip})
  end

  # GenServer

  defcast stop, do: stop_server(:normal)

  def handle_call({:send, gossip}, _from, state)
  when Gossip.is_valid(gossip)
  do
    [socket: socket, own_id: _own_id, multicast_id: multi_id, key: key] = state
    packet = Serializer.encode(gossip, key)
    case :gen_udp.send(socket, NetID.ip(multi_id), NetID.port(multi_id), packet)
    do
      :ok ->
        {:reply, :ok, state}

      {:error, reason} ->
        :gen_udp.close(socket)
        {:stop, reason, :error, state}
    end
  end

  # incoming handler
  def handle_info({:udp, socket, _ip, _port, data}, state)
  do
    [socket: _socket, own_id: own_id, multicast_id: _multi_id, key: key] = state
    # process data
    case Serializer.decode(data, key)
    do
      {:ok, gossip} ->
        peer_db = PeerDB.locate!
        my_seqno = case PeerDB.get_broadcast_seqno_(own_id) do
          {:ok, tmp_seqno} -> tmp_seqno
          {:error, _} -> 0
        end

        # register that we have seen the peer
        PeerDB.add_seen_id(peer_db,
                           BroadcastID.new(own_id, my_seqno),
                           Gossip.current_id(gossip))
        # register whom the peer have seen
        PeerDB.add_seen_id_list(peer_db,
                                Gossip.current_id(gossip),
                                Gossip.seen_ids(gossip))

        ## Logger.debug "received on multicast [#{inspect gossip}] size=[#{byte_size data}]"
        {:ok, _} = Receiver.handle(Receiver.locate!, Gossip.payload(gossip))

      {:error, :invalid_data, _}
        -> :error
    end

    # when we popped one message we allow one more to be buffered
    :inet.setopts(socket, [active: 1])
    {:noreply, state}
  end

  def handle_info(_msg, state)
  do
    {:noreply, state}
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
