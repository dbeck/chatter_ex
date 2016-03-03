defmodule Chatter.SerializerTest do
  use ExUnit.Case

  alias Chatter.Gossip
  alias Chatter.Serializer
  alias Chatter.NetID
  alias Chatter.BroadcastID
  alias Chatter.MessageHandler
  alias Chatter.SerializerDB

  @default_key "01234567890123456789012345678901"

  @default_gossip {:gossip,
          {:broadcast_id, {:net_id, {192, 168, 1, 97}, 29999}, 4},
          [{:broadcast_id, {:net_id, {192, 168, 1, 100}, 29999}, 3},
           {:broadcast_id, {:net_id, {192, 168, 1, 134}, 29999}, 1}],
          [{:broadcast_id, {:net_id, {192, 168, 1, 100}, 29999}, 3}],
          [{:net_id, {192, 168, 1, 97}, 29999},
           {:net_id, {192, 168, 1, 100}, 29999},
           {:net_id, {192, 168, 1, 134}, 29999}],
          {:serializable}}

  defp dummy_me do
    NetID.new({1,2,3,4},1)
  end

  defp dummy_serializable do
    id = BroadcastID.new(dummy_me, 111)
    extract_fn   = fn(id) -> BroadcastID.extract_netids(id) end
    encode_fn    = fn(id, ids) -> BroadcastID.encode_with(id, ids) end
    decode_fn    = fn(bin, ids) -> BroadcastID.decode_with(bin, ids) end
    dispatch_fn  = fn(id) -> {:ok, id} end
    encdec = MessageHandler.new(id, extract_fn, encode_fn, decode_fn, dispatch_fn)
    SerializerDB.add(SerializerDB.locate!, encdec)
    {:ok, _encded} = SerializerDB.get(SerializerDB.locate!, id)
    id
  end

  def dummy_gossip do
    @default_gossip |> Tuple.delete_at(5) |> Tuple.append(dummy_serializable)
  end

  test "encode and decode works together" do
    g = dummy_gossip
    assert Gossip.valid?(g)
    encoded = Serializer.encode(g, @default_key)
    assert {:ok, decoded} = Serializer.decode(encoded, @default_key)
    assert Gossip.valid?(decoded)
    assert g == decoded
  end

  test "encode only works with valid Gossip" do
  	assert_raise FunctionClauseError, fn -> Serializer.encode(nil, @default_key) end
    assert_raise FunctionClauseError, fn -> Serializer.encode([], @default_key) end
    assert_raise FunctionClauseError, fn -> Serializer.encode({}, @default_key) end
    assert_raise FunctionClauseError, fn -> Serializer.encode({:ok}, @default_key) end
    assert_raise FunctionClauseError, fn -> Serializer.encode({:ok, nil}, @default_key) end
    assert_raise FunctionClauseError, fn -> Serializer.encode({:ok, nil, nil}, @default_key) end
    assert_raise FunctionClauseError, fn -> Serializer.encode({:gossip, nil}, @default_key) end
    assert_raise FunctionClauseError, fn -> Serializer.encode({:gossip, nil, nil}, @default_key) end
    assert_raise FunctionClauseError, fn -> Serializer.encode({:gossip, nil, nil, nil}, @default_key) end
  end

  test "decode returns error on invalid input" do
    assert_raise FunctionClauseError, fn -> Serializer.decode("hello world" <> @default_key <> @default_key, @default_key) end
  	assert {:error, :invalid_data, _code} = Serializer.decode(<< 0xff >> <> "hello world" <> @default_key, @default_key)
  end

  test "encode() and decode() gossip works together" do
    assert Gossip.valid?(dummy_gossip)
    assert {:ok, dummy_gossip} == Serializer.encode(dummy_gossip, @default_key) |> Serializer.decode(@default_key)
  end

  test "encode_gossip() and decode_gossip() works together" do
    encoded = Serializer.encode_gossip(dummy_gossip)
    {decoded, <<>>} = Serializer.decode_gossip(encoded)
    assert decoded == dummy_gossip
  end

  test "encode_uint() and decode_uint() works together" do
    assert :ok == check_me(1000000000)
  end

  defp encode_and_decode(i)
  when is_integer(i) and
       i >= 0
  do
    encoded = Serializer.encode_uint(i)
    {decoded, <<>>} = Serializer.decode_uint(encoded)
    assert i == decoded
    if i == decoded
    do
      :ok
    else
      {:error, i, decoded}
    end
  end

  defp check_me(0)
  do
    :ok = encode_and_decode(0)
  end

  defp check_me(i)
  when is_integer(i) and
       i > 10000
  do
    :ok = encode_and_decode(i)
    r = Enum.take_random(1..100,1) |> hd
    check_me(div(i,r))
  end

  defp check_me(i)
  when is_integer(i) and
       i > 0
  do
    :ok = encode_and_decode(i)
    check_me(i-1)
  end

  # serialize registered vs unregistered
end
