defmodule Chatter.PeerDB do

  use ExActor.GenServer
  require Chatter.PeerData
  require Chatter.NetID
  require Chatter.BroadcastID
  alias Chatter.PeerData
  alias Chatter.NetID
  alias Chatter.BroadcastID

  defstart start_link([], opts),
    gen_server_opts: opts
  do
    name = Keyword.get(opts, :name, id_atom())
    table = :ets.new(name, [:named_table, :set, :protected, {:keypos, 2}])
    initial_state(
      [
        received_from: PeerData.new(Chatter.local_netid),
        can_send_to: table
      ])
  end

  # Convenience API
  def add(_pid, []), do: :ok

  def add(pid, id_list)
  when is_pid(pid)
  do
    :ok = NetID.validate_list!(id_list)
    GenServer.cast(pid, {:add, id_list})
  end

  def get_senders(pid)
  when is_pid(pid)
  do
    GenServer.call(pid, {:get_senders})
  end

  def local_seen_peer(pid, seen_id)
  when is_pid(pid) and
       BroadcastID.is_valid(seen_id)
  do
    GenServer.cast(pid, {:local_seen_peer, seen_id})
  end

  def peer_seen_others(pid, current_id, seen_id_list)
  when is_pid(pid) and
       BroadcastID.is_valid(current_id) and
       is_list(seen_id_list)
  do
    :ok = BroadcastID.validate_list(seen_id_list)
    GenServer.cast(pid, {:peer_seen_others, current_id, seen_id_list})
  end

  def inc_broadcast_seqno(pid)
  when is_pid(pid)
  do
    GenServer.call(pid, {:inc_broadcast_seqno})
  end

  # Direct, read-only ETS access
  # note: since the writer process may be slower than the readers
  #       the direct readers may not see the immediate result of the
  #       writes

  def get_(id)
  when NetID.is_valid(id)
  do
    name = id_atom()
    case :ets.lookup(name, id)
    do
      []      -> {:error, :not_found}
      [value] -> {:ok, value}
    end
  end

  def get_seen_id_list_(id)
  when NetID.is_valid(id)
  do
    name = id_atom()
    case :ets.lookup(name, id)
    do
      []      -> {:error, :not_found}
      [value] -> {:ok, PeerData.seen_ids(value)}
    end
  end

  def get_peers_()
  do
    name = id_atom()
    map = :ets.foldl(fn(e, acc) ->
      acc = Map.put(acc, PeerData.id(e),0)
      PeerData.seen_ids(e) |> Enum.reduce(acc, fn(x,v) ->
        Map.put(v, BroadcastID.origin(x), 0)
      end)
    end,
    %{},
    name)
    Map.keys(map)
  end

  # GenServer

  ########## Casts #####################

  defcast stop, do: stop_server(:normal)

  def handle_cast({:add, id_list},
                  [received_from: senders, can_send_to: table])
  do
    :ok = add_ids(id_list, table)
    {:noreply, [received_from: senders, can_send_to: table]}
  end

  def handle_cast({:local_seen_peer, seen_id},
                  [received_from: senders, can_send_to: table])
  when BroadcastID.is_valid(seen_id)
  do
    updated_senders = PeerData.merge_seen_ids(senders, [seen_id])
    {:noreply, [received_from: updated_senders, can_send_to: table]}
  end

  def handle_cast({:peer_seen_others, current_id, seen_ids},
                  [received_from: senders, can_send_to: table])
  when BroadcastID.is_valid(current_id) and
       is_list(seen_ids)
  do
    combined = [current_id | seen_ids]
    :ok = add_ids(combined, table)
    :ok = update_seqnos(combined, table)
    :ok = update_seen_ids(current_id, seen_ids, table)
    {:noreply, [received_from: senders, can_send_to: table]}
  end

  ########## Calls #####################

  def handle_call({:get_senders},
                _from,
                [received_from: senders, can_send_to: table])
  do
    {:reply, {:ok, PeerData.seen_ids(senders)}, [received_from: senders, can_send_to: table]}
  end

  def handle_call({:inc_broadcast_seqno},
                  _from,
                  [received_from: senders, can_send_to: table])
  do
    updated_value = PeerData.inc_broadcast_seqno(senders)
    updated_seqno = PeerData.broadcast_seqno(updated_value)
    {:reply, {:ok, updated_seqno}, [received_from: updated_value, can_send_to: table]}
  end

  ########## Private helpers #####################

  defp add_ids([], _table), do: :ok

  defp add_ids([head|rest], table)
  when BroadcastID.is_valid(head)
  do
    head_netid = BroadcastID.origin(head)
    :ets.insert_new(table, PeerData.new(head_netid))
    add_ids(rest, table)
  end

  defp add_ids([head|rest], table)
  when NetID.is_valid(head)
  do
    :ets.insert_new(table, PeerData.new(head))
    add_ids(rest, table)
  end

  defp update_seqnos([], _table), do: :ok

  defp update_seqnos([head|rest], table)
  do
    head_netid = BroadcastID.origin(head)
    head_seqno = BroadcastID.seqno(head)

    case :ets.lookup(table, head_netid)
    do
      [] ->
        :error

      [value] ->
        updated_value = PeerData.max_broadcast_seqno(value, head_seqno)
        :ets.insert(table, updated_value)
        update_seqnos(rest, table)
    end
  end

  defp update_seen_ids(_current_id, [], _table), do: :ok

  defp update_seen_ids(current_id, [head|rest], table)
  do
    netid = BroadcastID.origin(head)

    case :ets.lookup(table, netid)
    do
      [] ->
        :error

      [value] ->
        updated_value = PeerData.merge_seen_ids(value, [current_id])
        true = :ets.insert(table, updated_value)
        update_seen_ids(current_id, rest, table)
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
