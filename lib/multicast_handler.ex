defmodule Chatter.MulticastHandler do

  use ExActor.GenServer
  require Chatter.Gossip
  require Chatter.BroadcastID
  require Chatter.NetID
  require Logger
  alias Chatter.Gossip
  alias Chatter.PeerDB
  alias Chatter.NetID
  alias Chatter.Serializer
  alias Chatter.SerializerDB
  alias Chatter.BroadcastID
  alias Chatter.MessageHandler

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
    try do
      case Serializer.decode(data, key)
      do
        {:ok, gossip} ->
          peer_db = PeerDB.locate!

          # register that we have seen the peer
          PeerDB.local_seen_peer(peer_db,
                                 Gossip.current_id(gossip))

          # register whom the peer has seen
          PeerDB.peer_seen_others(peer_db,
                                  Gossip.current_id(gossip),
                                  Gossip.seen_ids(gossip))

          # register the other nodes the peer knows about
          PeerDB.add(peer_db, Gossip.other_ids(gossip))

          {:ok, handler} = SerializerDB.get_(Gossip.payload(gossip))

          ## Logger.debug "received on multicast [#{inspect gossip}] size=[#{byte_size data}]"
          {:ok, _} = MessageHandler.dispatch(handler, Gossip.payload(gossip))

        {:error, :invalid_data, _}
          -> :error
      end
    rescue
      MatchError -> Logger.error "MatchError: cannot decode packet size=[#{byte_size data}]"
      _ -> Logger.error "Unexpected Error: cannot decode packet size=[#{byte_size data}]"
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
