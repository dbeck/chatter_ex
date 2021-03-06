defmodule Chatter.Gossip do

  require Record
  require Chatter.BroadcastID
  require Chatter.NetID
  alias Chatter.BroadcastID
  alias Chatter.NetID

  Record.defrecord :gossip,
                   current_id: nil,
                   seen_ids: [],
                   other_ids: [],
                   distribution_list: [],
                   payload: nil

  @type t :: record( :gossip,
                     current_id: BroadcastID.t,
                     seen_ids: list(BroadcastID.t),
                     other_ids: list(NetID.t),
                     distribution_list: list(NetID.t),
                     payload: tuple )

  @spec new(NetID.t, tuple) :: t
  def new(my_id, data)
  when NetID.is_valid(my_id) and
       is_tuple(data) and
       tuple_size(data) > 1
  do
    gossip(current_id: BroadcastID.new(my_id)) |> gossip(payload: data)
  end

  @spec new(NetID.t, integer, tuple) :: t
  def new(my_id, seqno, data)
  when NetID.is_valid(my_id) and
       is_integer(seqno) and
       seqno >= 0 and
       is_tuple(data) and
       tuple_size(data) > 1
  do
    gossip(current_id: BroadcastID.new(my_id) |> BroadcastID.seqno(seqno))
    |> gossip(payload: data)
  end

  defmacro is_valid(data) do
    case Macro.Env.in_guard?(__CALLER__) do
      true ->
        quote do
          is_tuple(unquote(data)) and tuple_size(unquote(data)) == 6 and
          :erlang.element(1, unquote(data)) == :gossip and
          # broadcast id
          BroadcastID.is_valid(:erlang.element(2, unquote(data))) and
          # seen ids
          is_list(:erlang.element(3, unquote(data))) and
          # other ids
          is_list(:erlang.element(4, unquote(data))) and
          # distribution list
          is_list(:erlang.element(5, unquote(data))) and
          # payload
          is_tuple(:erlang.element(6, unquote(data))) and
          tuple_size(:erlang.element(6, unquote(data))) > 1
        end
      false ->
        quote bind_quoted: binding() do
          is_tuple(data) and tuple_size(data) == 6 and
          :erlang.element(1, data) == :gossip and
          # broadcast id
          BroadcastID.is_valid(:erlang.element(2, data)) and
          # seen ids
          is_list(:erlang.element(3, data)) and
          # other ids
          is_list(:erlang.element(4, data)) and
          # distribution list
          is_list(:erlang.element(5, data)) and
          # payload
          is_tuple(:erlang.element(6, data)) and
          tuple_size(:erlang.element(6, data)) > 1
        end
    end
  end

  defmacro is_valid_relaxed(data) do
    case Macro.Env.in_guard?(__CALLER__) do
      true ->
        quote do
          is_tuple(unquote(data)) and tuple_size(unquote(data)) == 6 and
          :erlang.element(1, unquote(data)) == :gossip and
          # broadcast id
          BroadcastID.is_valid(:erlang.element(2, unquote(data))) and
          # seen ids
          is_list(:erlang.element(3, unquote(data))) and
          # other ids
          is_list(:erlang.element(4, unquote(data))) and
          # distribution list
          is_list(:erlang.element(5, unquote(data)))
        end
      false ->
        quote bind_quoted: binding() do
          is_tuple(data) and tuple_size(data) == 6 and
          :erlang.element(1, data) == :gossip and
          # broadcast id
          BroadcastID.is_valid(:erlang.element(2, data)) and
          # seen ids
          is_list(:erlang.element(3, data)) and
          # other ids
          is_list(:erlang.element(4, data)) and
          # distribution list
          is_list(:erlang.element(5, data))
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

  @spec current_id(t) :: BroadcastID.t
  def current_id(g)
  when is_valid(g)
  do
    gossip(g, :current_id)
  end

  @spec seen_ids(t, list(BroadcastID.t)) :: t
  def seen_ids(g, ids)
  when is_valid(g) and
       is_list(ids)
  do
    :ok = BroadcastID.validate_list!(ids)
    gossip(g, seen_ids: ids)
  end

  @spec seen_ids(t) :: list(BroadcastID.t)
  def seen_ids(g)
  when is_valid(g)
  do
    gossip(g, :seen_ids)
  end

  @spec other_ids(t, list(NetID.t)) :: t
  def other_ids(g, ids)
  when is_valid(g) and
       is_list(ids)
  do
    :ok = NetID.validate_list!(ids)
    gossip(g, other_ids: ids)
  end

  @spec other_ids(t) :: list(NetID.t)
  def other_ids(g)
  when is_valid(g)
  do
    gossip(g, :other_ids)
  end

  @spec payload(t) :: tuple
  def payload(g)
  when is_valid(g)
  do
    gossip(g, :payload)
  end

  @spec payload(t, tuple) :: t
  def payload(g, pl)
  when is_valid(g) and
       is_tuple(pl) and
       tuple_size(pl) > 1
  do
    gossip(g, payload: pl)
  end

  @spec payload_relaxed(t, tuple) :: t
  def payload_relaxed(g, pl)
  when is_valid_relaxed(g) and
       is_tuple(pl) and
       tuple_size(pl) > 1
  do
    gossip(g, payload: pl)
  end

  @spec seen_netids(t) :: list(NetID.t)
  def seen_netids(g)
  when is_valid(g)
  do
    Enum.reduce(gossip(g, :seen_ids), [], fn(x, acc) ->
      [Chatter.BroadcastID.origin(x)|acc]
    end)
  end

  @spec distribution_list(t, list(NetID.t)) :: t
  def distribution_list(g, ids)
  when is_valid(g) and
       is_list(ids)
  do
    :ok = NetID.validate_list!(ids)
    gossip(g, distribution_list: ids)
  end

  @spec distribution_list(t) :: list(NetID.t)
  def distribution_list(g)
  when is_valid(g)
  do
    gossip(g, :distribution_list)
  end

  @spec remove_from_distribution_list(t, list(NetID.t)) :: t
  def remove_from_distribution_list(g, [])
  when is_valid(g)
  do
    g
  end

  def remove_from_distribution_list(g, to_remove)
  when is_valid(g)
  do
    :ok = NetID.validate_list!(to_remove)
    old_list = gossip(g, :distribution_list)
    old_set = Enum.into(old_list, HashSet.new)
    remove_set = Enum.into(to_remove, HashSet.new)
    new_set = HashSet.difference(old_set, remove_set)
    gossip(g, distribution_list: HashSet.to_list(new_set))
  end

  @spec add_to_distribution_list(t, list(NetID.t)) :: t
  def add_to_distribution_list(g, [])
  when is_valid(g)
  do
    g
  end

  def add_to_distribution_list(g, to_add)
  when is_valid(g)
  do
    :ok = NetID.validate_list!(to_add)
    old_list = gossip(g, :distribution_list)
    old_set = Enum.into(old_list, HashSet.new)
    add_set = Enum.into(to_add, HashSet.new)
    new_set = HashSet.union(old_set, add_set)
    gossip(g, distribution_list: HashSet.to_list(new_set))
  end

  @spec extract_netids(t) :: list(NetID.t)
  def extract_netids(g)
  when is_valid(g)
  do
    [gossip(g, :current_id) |> BroadcastID.origin | gossip(g, :distribution_list)] ++
    Enum.map(gossip(g, :seen_ids), fn(x) -> BroadcastID.origin(x) end) ++
    gossip(g, :other_ids)
    |> Enum.uniq
  end

  @spec encode_with(t, map) :: binary
  def encode_with(g, id_map)
  when is_valid(g) and
       is_map(id_map) # TODO: check map too ...
  do
    bin_current_id    = gossip(g, :current_id)        |> BroadcastID.encode_with(id_map)
    bin_seen_ids      = gossip(g, :seen_ids)          |> BroadcastID.encode_list_with(id_map)
    bin_other_ids     = gossip(g, :other_ids)         |> NetID.encode_list_with(id_map)
    bin_distrib       = gossip(g, :distribution_list) |> NetID.encode_list_with(id_map)

    << bin_current_id     :: binary,
       bin_seen_ids       :: binary,
       bin_other_ids      :: binary,
       bin_distrib        :: binary >>
  end

  @spec decode_with(binary, map) :: {t, binary}
  def decode_with(bin, id_map)
  when is_binary(bin) and
       byte_size(bin) > 0 and
       is_map(id_map)
  do
    {decoded_current_id, remaining} = BroadcastID.decode_with(bin, id_map)
    {decoded_seen_ids, remaining}   = BroadcastID.decode_list_with(remaining, id_map)
    {decoded_other_ids, remaining}  = NetID.decode_list_with(remaining, id_map)
    {decoded_distrib, remaining}    = NetID.decode_list_with(remaining, id_map)

    { gossip([current_id: decoded_current_id,
              seen_ids: decoded_seen_ids,
              other_ids: decoded_other_ids,
              distribution_list: decoded_distrib,
              payload: :empty]),
      remaining }
  end
end
