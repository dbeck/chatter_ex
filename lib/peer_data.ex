defmodule GroupManager.Chatter.PeerData do

  require Record
  require Common.NetID
  require Common.BroadcastID
  alias Common.NetID
  alias Common.BroadcastID

  Record.defrecord :peer_data,
                   id: nil,
                   broadcast_seqno: 0,
                   seen_ids: []

  @type t :: record( :peer_data,
                     id: NetID.t,
                     broadcast_seqno: integer,
                     seen_ids: list(BroadcastID.t) )

  @spec new(NetID.t) :: t
  def new(id)
  when NetID.is_valid(id)
  do
    peer_data(id: id)
  end

  defmacro is_valid(data) do
    case Macro.Env.in_guard?(__CALLER__) do
      true ->
        quote do
          is_tuple(unquote(data)) and tuple_size(unquote(data)) == 4 and
          :erlang.element(1, unquote(data)) == :peer_data and
          # id
          NetID.is_valid(:erlang.element(2, unquote(data))) and
          # broadcast_seqno
          is_integer(:erlang.element(3, unquote(data))) and
          :erlang.element(3, unquote(data)) >= 0 and
          # seen ids
          is_list(:erlang.element(4, unquote(data)))
        end
      false ->
        quote bind_quoted: binding() do
          is_tuple(data) and tuple_size(data) == 4 and
          :erlang.element(1, data) == :peer_data and
          # id
          NetID.is_valid(:erlang.element(2, data)) and
          # broadcast_seqno
          is_integer(:erlang.element(3, data)) and
          :erlang.element(3, data) >= 0 and
          # seen ids
          is_list(:erlang.element(4, data))
        end
    end
  end

  @spec valid?(t) :: boolean
  def valid?(data)
  when is_valid(data)
  do
    true
  end

  def valid?(_), do: false

  @spec id(t) :: NetID.t
  def id(d)
  when is_valid(d)
  do
    peer_data(d, :id)
  end

  @spec inc_broadcast_seqno(t) :: integer
  def inc_broadcast_seqno(d)
  when is_valid(d)
  do
    peer_data(d, broadcast_seqno: (1+peer_data(d, :broadcast_seqno)))
  end

  @spec broadcast_seqno(t) :: integer
  def broadcast_seqno(d)
  when is_valid(d)
  do
    peer_data(d, :broadcast_seqno)
  end

  @spec broadcast_seqno(t, integer) :: t
  def broadcast_seqno(d, v)
  when is_valid(d) and
       is_integer(v) and
       v >= 0
  do
    peer_data(d, broadcast_seqno: v)
  end

  @spec max_broadcast_seqno(t, integer) :: t
  def max_broadcast_seqno(d, v)
  when is_valid(d) and is_integer(v) and v >= 0
  do
    peer_data(d, broadcast_seqno: max(v, peer_data(d, :broadcast_seqno)))
  end

  @spec seen_ids(t) :: list(BroadcastID.t)
  def seen_ids(d)
  when is_valid(d)
  do
    peer_data(d, :seen_ids)
  end

  @spec merge_seen_ids(t, list(BroadcastID.t)) :: t
  def merge_seen_ids(d, []), do: d

  def merge_seen_ids(d, ids)
  when is_valid(d) and
       is_list(ids)
  do
    old_ids = peer_data(d, :seen_ids)
    peer_data(d, seen_ids: BroadcastID.merge_lists(old_ids, ids))
  end
end
