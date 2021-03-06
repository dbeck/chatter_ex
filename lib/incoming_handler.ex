defmodule Chatter.IncomingHandler do

  require Chatter.Gossip
  require Chatter.BroadcastID
  require Chatter.NetID
  require Logger
  alias Chatter.Gossip
  alias Chatter.PeerDB
  alias Chatter
  alias Chatter.NetID
  alias Chatter.Serializer
  alias Chatter.SerializerDB
  alias Chatter.MessageHandler

  def start_link(ref, socket, transport, opts) do
    pid = spawn_link(__MODULE__, :init, [ref, socket, transport, opts])
    {:ok, pid}
  end

  def init(ref, socket, transport, opts) do
    :ok = :ranch.accept_ack(ref)
    own_id = Keyword.get(opts, :own_id)
    key    = Keyword.get(opts, :key)
    timeout_seconds = Keyword.get(opts, :timeout_seconds, 60)
    loop(socket, transport, own_id, timeout_seconds, 0, key)
  end

  def loop(socket, transport, _own_id, timeout_seconds, act_wait, _key)
  when act_wait >= timeout_seconds
  do
    :ok = transport.close(socket)
  end

  def loop(socket, transport, own_id, timeout_seconds, act_wait, key)
  when NetID.is_valid(own_id) and
       is_integer(timeout_seconds) and
       is_integer(act_wait) and
       act_wait < timeout_seconds and
       is_binary(key) and
       byte_size(key) == 32
  do
    case transport.recv(socket, 0, 5000) do
      {:ok, data} ->
        # process data
        try do
          case Serializer.decode(data, key)
          do
            {:ok, gossip} ->
              peer_db = PeerDB.locate!

              # register the peer who sent us the message
              PeerDB.add(peer_db, Gossip.current_id(gossip))

              # register whom the peer has seen
              PeerDB.peer_seen_others(peer_db,
                                      Gossip.current_id(gossip),
                                      Gossip.seen_ids(gossip))

              # register the other nodes the peer knows about
              PeerDB.add(peer_db, Gossip.other_ids(gossip))

              {:ok, handler} = SerializerDB.get_(Gossip.payload(gossip))

              ## Logger.debug "received on TCP [#{inspect gossip}] size=[#{byte_size data}]"
              {:ok, new_message} = MessageHandler.dispatch(handler, Gossip.payload(gossip))

              # make sure we pass the message forward with the modified payload
              :ok = Chatter.broadcast(gossip |> Gossip.payload(new_message))

              loop(socket, transport, own_id, timeout_seconds, 0, key)

            {:error, :invalid_data, _} ->
              :ok = transport.close(socket)
          end
        rescue
          MatchError -> Logger.error "MatchError: cannot decode packet size=[#{byte_size data}]. closing TCP connection"
          _ -> Logger.error "Unexpected Error: cannot decode packet size=[#{byte_size data}]. closing TCP connection"
          :ok = transport.close(socket)
        end

      {:error, :timeout} ->
        loop(socket, transport, own_id, timeout_seconds, act_wait+5, key)

      _ ->
        :ok = transport.close(socket)
    end
  end
end
