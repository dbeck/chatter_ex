defmodule Common.SerializerTest do
  use ExUnit.Case

  alias GroupManager.Chatter.Gossip
  alias Common.Serializer
  alias Common.NetID
  alias GroupManager.Data.Message

  @default_key "01234567890123456789012345678901"

  @default_gossip {:gossip,
          {:broadcast_id, {:net_id, {192, 168, 1, 97}, 29999}, 4},
          [{:broadcast_id, {:net_id, {192, 168, 1, 100}, 29999}, 3},
           {:broadcast_id, {:net_id, {192, 168, 1, 134}, 29999}, 1}],
          [{:net_id, {192, 168, 1, 97}, 29999},
           {:net_id, {192, 168, 1, 100}, 29999},
           {:net_id, {192, 168, 1, 134}, 29999}],
          {:message,
           {:world_clock,
            [{:local_clock, {:net_id, {192, 168, 1, 97}, 29999}, 2},
             {:local_clock, {:net_id, {192, 168, 1, 100}, 29999}, 0},
             {:local_clock, {:net_id, {192, 168, 1, 134}, 29999}, 0}]},
           {:timed_set,
            [{:timed_item, {:item, {:net_id, {192, 168, 1, 97}, 29999}, :get, 0, 4294967295, 0},
                           {:local_clock, {:net_id, {192, 168, 1, 97}, 29999}, 2}},
             {:timed_item, {:item, {:net_id, {192, 168, 1, 100}, 29999}, :get, 0, 4294967295, 0},
                           {:local_clock, {:net_id, {192, 168, 1, 100}, 29999}, 0}},
             {:timed_item, {:item, {:net_id, {192, 168, 1, 134}, 29999}, :get, 0, 4294967295, 0},
                           {:local_clock, {:net_id, {192, 168, 1, 134}, 29999}, 0}}]}, "G"}}


  defp dummy_me do
    NetID.new({1,2,3,4},1)
  end

  test "encode and decode works together" do
    g = Gossip.new(dummy_me, 9999, Message.new("hello"))
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
    assert Gossip.valid?(@default_gossip)
    assert {:ok, @default_gossip} == Serializer.encode(@default_gossip, @default_key) |> Serializer.decode(@default_key)
  end

  test "encode_gossip() and decode_gossip() works together" do
    encoded = Serializer.encode_gossip(@default_gossip)
    {decoded, <<>>} = Serializer.decode_gossip(encoded)
    assert decoded == @default_gossip
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
end
