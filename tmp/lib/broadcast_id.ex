defmodule Chatter.BroadcastID do

  require Record
  require Chatter.NetID
  alias Chatter.NetID
  alias Chatter.Serializer

  Record.defrecord :broadcast_id,
                   origin: nil,
                   seqno: 0

  @type t :: record( :broadcast_id,
                     origin: NetID.t,
                     seqno: integer )

  @spec new(NetID.t) :: t
  def new(id)
  when NetID.is_valid(id)
  do
    broadcast_id(origin: id)
  end

  @spec new(NetID.t, integer) :: t
  def new(id, seqno)
  when NetID.is_valid(id) and
       is_integer(seqno) and
       seqno >= 0
  do
    broadcast_id(origin: id) |> broadcast_id(seqno: seqno)
  end

  defmacro is_valid(data) do
    case Macro.Env.in_guard?(__CALLER__) do
      true ->
        quote do
          is_tuple(unquote(data)) and tuple_size(unquote(data)) == 3 and
          :erlang.element(1, unquote(data)) == :broadcast_id and
          # origin
          NetID.is_valid(:erlang.element(2, unquote(data))) and
          # seqno
          is_integer(:erlang.element(3, unquote(data))) and
          :erlang.element(3, unquote(data)) >= 0
        end
      false ->
        quote bind_quoted: binding() do
          is_tuple(unquote(data)) and tuple_size(data) == 3 and
          :erlang.element(1, data) == :broadcast_id and
          # origin
          NetID.is_valid(:erlang.element(2, data)) and
          # seqno
          is_integer(:erlang.element(3, data)) and
          :erlang.element(3, data) >= 0
        end
    end
  end

  @spec origin(t) :: NetID.t
  def origin(id)
  when is_valid(id)
  do
    broadcast_id(id, :origin)
  end

  @spec origin(t,  NetID.t) :: t
  def origin(id, nid)
  when is_valid(id) and
       NetID.is_valid(nid)
  do
    broadcast_id(id, origin: nid)
  end

  @spec seqno(t) :: NetID.t
  def seqno(id)
  when is_valid(id)
  do
    broadcast_id(id, :seqno)
  end

  @spec seqno(t, integer) :: t
  def seqno(id, v)
  when is_valid(id) and
       is_integer(v) and
       v >= 0
  do
    broadcast_id(id, seqno: v)
  end

  @spec inc_seqno(t) :: t
  def inc_seqno(id)
  when is_valid(id)
  do
    broadcast_id(id, seqno: broadcast_id(id, :seqno)+1)
  end

  @spec valid?(t) :: boolean
  def valid?(data)
  when is_valid(data)
  do
    true
  end

  def valid?(_), do: false

  @spec validate_list(list(t)) :: :ok | :error
  def validate_list([]), do: :ok

  def validate_list([head|rest])
  do
    case valid?(head) do
      true -> validate_list(rest)
      false -> :error
    end
  end

  def validate_list(_), do: :error

  @spec validate_list!(list(t)) :: :ok
  def validate_list!([]), do: :ok

  def validate_list!([head|rest])
  when is_valid(head)
  do
    validate_list!(rest)
  end

  @spec merge_lists(list(BroadcastID.t), list(BroadcastID.t)) :: list(BroadcastID.t)
  def merge_lists([], []), do: []
  def merge_lists(lhs, []) when is_list(lhs), do: lhs
  def merge_lists([], rhs) when is_list(rhs), do: rhs

  def merge_lists(lhs, rhs)
  when is_list(lhs) and
       is_list(rhs)
  do
    # optimize this ???
    dict = Enum.map(lhs ++ rhs, fn(x) -> {origin(x), seqno(x)} end)
    |> Enum.reduce(%{}, fn({m, t} ,acc) ->
      Map.update(acc, m, t, fn(prev_seqno) ->
        max(t, prev_seqno)
      end)
    end)
    Enum.map(Map.keys(dict), fn(k) -> broadcast_id(origin: k) |> broadcast_id(seqno: Map.get(dict, k)) end)
  end

  @spec extract_netids(t) :: list(NetID.t)
  def extract_netids(id)
  when is_valid(id)
  do
    [broadcast_id(id, :origin)]
  end

  @spec encode_with(t, map) :: binary
  def encode_with(b, id_map)
  when is_valid(b) and
       is_map(id_map) # TODO: check map too ...
  do
    id = Map.fetch!(id_map, broadcast_id(b, :origin))
    << Serializer.encode_uint(id) :: binary, Serializer.encode_uint(broadcast_id(b, :seqno)) :: binary >>
  end

  @spec encode_list_with(list(t), map) :: binary
  def encode_list_with(ids, id_map)
  when is_list(ids) and
       is_map(id_map)
  do
    :ok = validate_list!(ids)
    bin_size  = ids |> length |> Serializer.encode_uint
    bin_list  = ids |> Enum.reduce(<<>>, fn(x,acc) ->
      acc <> encode_with(x, id_map)
    end)
    << bin_size :: binary,
       bin_list :: binary >>
  end

  @spec decode_with(binary, map) :: {t, binary}
  def decode_with(bin, id_map)
  when is_binary(bin) and
       byte_size(bin) > 0 and
       is_map(id_map)
  do
    {id, rest}    = Serializer.decode_uint(bin)
    {seqno, rest} = Serializer.decode_uint(rest)
    net_id        = Map.fetch!(id_map, id)
    {new(net_id, seqno), rest}
  end

  @spec decode_list_with(binary, map) :: {list(t), binary}
  def decode_list_with(bin, id_map)
  do
    {count, remaining} = Serializer.decode_uint(bin)
    {list, remaining} = decode_list_with_(remaining, count, [], id_map)
    {Enum.reverse(list), remaining}
  end

  defp decode_list_with_(<<>>, _count, acc, _map), do: {acc, <<>>}
  defp decode_list_with_(binary, 0, acc, _map), do: {acc, binary}

  defp decode_list_with_(msg, count, acc, map)
  when is_binary(msg) and
       is_integer(count) and
       count > 0 and
       is_list(acc) and
       is_map(map)
  do
    {id, remaining} = decode_with(msg, map)
    decode_list_with_(remaining, count-1, [id | acc], map)
  end
end
