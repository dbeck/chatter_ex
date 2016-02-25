defmodule GroupManager.Chatter.PeerDB do

  use ExActor.GenServer
  require GroupManager.Chatter.PeerData
  require Common.NetID
  require Common.BroadcastID
  alias GroupManager.Chatter.PeerData
  alias Common.NetID
  alias Common.BroadcastID

  defstart start_link([], opts),
    gen_server_opts: opts
  do
    name = Keyword.get(opts, :name, id_atom())
    table = :ets.new(name, [:named_table, :set, :protected, {:keypos, 2}])
    initial_state(table)
  end

  # Convenience API

  def add(pid, id)
  when is_pid(pid) and
       NetID.is_valid(id)
  do
    GenServer.cast(pid, {:add, id})
  end

  def get(pid, id)
  when is_pid(pid) and
       NetID.is_valid(id)
  do
    GenServer.call(pid, {:get, id})
  end

  def add_seen_id(pid, current_id, seen_id)
  when is_pid(pid) and
       BroadcastID.is_valid(current_id) and
       BroadcastID.is_valid(seen_id)
  do
    GenServer.cast(pid, {:add_seen_id_list, current_id, [seen_id]})
  end

  def add_seen_id_list(pid, current_id, seen_id_list)
  when is_pid(pid) and
       BroadcastID.is_valid(current_id) and
       is_list(seen_id_list)
  do
    :ok = BroadcastID.validate_list(seen_id_list)
    GenServer.cast(pid, {:add_seen_id_list, current_id, seen_id_list})
  end

  def inc_broadcast_seqno(pid, id)
  when is_pid(pid) and NetID.is_valid(id)
  do
    GenServer.call(pid, {:inc_broadcast_seqno, id})
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

  def get_broadcast_seqno_(id)
  when NetID.is_valid(id)
  do
    name = id_atom()
    case :ets.lookup(name, id)
    do
      []      -> {:error, :not_found}
      [value] -> {:ok, PeerData.broadcast_seqno(value)}
    end
  end

  # GenServer

  defcast stop, do: stop_server(:normal)

  def handle_cast({:add, id}, table)
  when NetID.is_valid(id)
  do
    :ets.insert_new(table, PeerData.new(id))
    {:noreply, table}
  end

  def handle_cast({:add_seen_id_list, current_id, seen_ids}, table)
  when BroadcastID.is_valid(current_id) and
       is_list(seen_ids)
  do
    combined = [current_id | seen_ids]
    :ok = add_ids(combined, table)
    :ok = update_seqnos(combined, table)
    :ok = update_seen_ids(current_id, seen_ids, table)
    { :noreply, table }
  end

  def handle_call({:get, id}, _from, table)
  when NetID.is_valid(id)
  do
    case :ets.lookup(table, id)
    do
      []      -> {:reply, :error, table}
      [value] -> {:reply, {:ok, value}, table}
    end
  end

  def handle_call({:inc_broadcast_seqno, id}, _from, table)
  when NetID.is_valid(id)
  do
    # make sure we have a placeholder ID in ETS
    :ets.insert_new(table, PeerData.new(id))

    # lookup and update
    case :ets.lookup(table, id)
    do
      []      -> {:reply, :error, table}
      [value] ->
        updated_value = PeerData.inc_broadcast_seqno(value)
        :ets.insert(table, updated_value)
        {:reply, {:ok, PeerData.broadcast_seqno(updated_value)}, table}
    end
  end

  defp add_ids([], _table), do: :ok

  defp add_ids([head|rest], table)
  do
    head_netid = BroadcastID.origin(head)
    :ets.insert_new(table, PeerData.new(head_netid))
    add_ids(rest, table)
  end

  defp update_seqnos([], _table), do: :ok

  defp update_seqnos([head|rest], table)
  do
    head_netid = BroadcastID.origin(head)
    head_seqno = BroadcastID.seqno(head)

    case :ets.lookup(table, head_netid)
    do
      [] -> :error

      [value] ->
        updated_value = PeerData.max_broadcast_seqno(value, head_seqno)
        :ets.insert(table, updated_value)
        update_seqnos(rest, table)
    end
  end

  defp update_seen_ids(_current_id, [], _table), do: :ok

  defp update_seen_ids(current_id, id_list, table)
  do
    netid = BroadcastID.origin(current_id)

    case :ets.lookup(table, netid)
    do
      [] -> :error

      [value] ->
        updated_value = PeerData.merge_seen_ids(value, id_list)
        true = :ets.insert(table, updated_value)
        :ok
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
