defmodule GroupManager.Chatter.OutgoingHandler do

  use ExActor.GenServer
  require GroupManager.Chatter.Gossip
  require Common.BroadcastID
  require Common.NetID
  require Logger
  alias GroupManager.Chatter.Gossip
  alias Common.NetID
  alias Common.Serializer

  defstart start_link([own_id: own_id, peer_id: peer_id, key: key], opts),
    gen_server_opts: opts
  do
    # kept 'active' so we can stop on anything from the other side
    opts = [:binary, active: true]
    true = NetID.valid?(peer_id)
    true = NetID.valid?(own_id)
    {:ok, socket} = :gen_tcp.connect(NetID.ip(peer_id), NetID.port(peer_id), opts)
    initial_state([socket: socket, own_id: own_id, peer_id: peer_id, key: key])
  end

  @spec send(pid, Gossip.t) :: Gossip.t
  def send(pid, gossip)
  when is_pid(pid) and
       Gossip.is_valid(gossip)
  do
    GenServer.call(pid, {:send, gossip})
  end

  # GenServer

  defcast stop, do: stop_server(:normal)

  def handle_call({:send, gossip}, _from, state)
  when Gossip.is_valid(gossip)
  do
    [socket: socket, own_id: _own_id, peer_id: _peer_id, key: key] = state
    data = Serializer.encode(gossip, key)
    ## Logger.debug "sending on TCP [#{inspect gossip}] size=[#{byte_size data}]"
    case :gen_tcp.send(socket, data)
    do
      :ok -> {:reply, :ok, state}
      {:error, reason} ->
        :gen_tcp.close(socket)
        {:stop, reason, :error, state}
    end
  end

  # stop on any message or event from the other side
  def handle_info({:tcp_closed, _port}, state), do: {:stop, :normal, state}
  def handle_info({:tcp_error, _port, reason}, state), do: {:stop, reason, state}
  def handle_info(_msg, state), do: {:stop, "unknown message received", state}

  def locate(id)
  when NetID.is_valid(id)
  do
    Process.whereis(id_atom(id))
  end

  def locate!(id)
  when NetID.is_valid(id)
  do
    case Process.whereis(id_atom(id)) do
      pid when is_pid(pid) ->
        pid
    end
  end

  def id_atom(id)
  when NetID.is_valid(id)
  do
    host = NetID.ip(id) |> :inet_parse.ntoa |> String.Chars.to_string
    String.to_atom("GroupManager.Chatter.OutgoingHandler.#{host}:#{NetID.port(id)}")
  end
end
