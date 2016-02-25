defmodule GroupManager.Chatter.IncomingHandler do

  require GroupManager.Chatter.Gossip
  require Common.BroadcastID
  require Common.NetID
  require Logger
  alias GroupManager.Chatter.Gossip
  alias GroupManager.Chatter.PeerDB
  alias GroupManager.Chatter
  alias GroupManager.Receiver
  alias Common.NetID
  alias Common.Serializer

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
        case Serializer.decode(data, key)
        do
          {:ok, gossip} ->
            peer_db = PeerDB.locate!

            # register whom the peer have seen
            PeerDB.add_seen_id_list(peer_db,
                                    Gossip.current_id(gossip),
                                    Gossip.seen_ids(gossip))

            ## Logger.debug "received on TCP [#{inspect gossip}] size=[#{byte_size data}]"
            {:ok, new_message} = Receiver.handle(Receiver.locate!, Gossip.payload(gossip))

            # make sure we pass the message forward with the modified payload
            :ok = Chatter.broadcast(gossip |> Gossip.payload(new_message))

            loop(socket, transport, own_id, timeout_seconds, 0, key)

          {:error, :invalid_data, _} ->
            :ok = transport.close(socket)
        end

      {:error, :timeout} ->
        loop(socket, transport, own_id, timeout_seconds, act_wait+5, key)

      _ ->
        :ok = transport.close(socket)
    end
  end
end
