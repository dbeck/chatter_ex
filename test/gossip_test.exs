defmodule GroupManager.Chatter.GossipTest do

  use ExUnit.Case
  alias GroupManager.Chatter.Gossip
  alias Common.NetID
  alias Common.BroadcastID

  test "basic test for new(netid, data)" do
    assert Gossip.valid?(Gossip.new(NetID.new({127,0,0,1}, 29999), []))
  end

  test "basic test for new(netid, seqno, data)" do
    g = Gossip.new(NetID.new({127,0,0,1}, 29999), 9999, [])
    assert Gossip.valid?(g)
    assert 9999 == g |> Gossip.current_id |> BroadcastID.seqno
  end

  test "basic test for invalid input" do
    assert Gossip.valid?(nil) == false
    assert Gossip.valid?([]) == false
    assert Gossip.valid?({}) == false
    assert Gossip.valid?(:ok) == false
    assert Gossip.valid?({:ok}) == false
    assert Gossip.valid?({:gossip}) == false
    assert Gossip.valid?({:gossip, nil}) == false
    assert Gossip.valid?({:gossip, nil, nil}) == false
    assert Gossip.valid?({:gossip, nil, nil, nil}) == false
  end

  # current_id
  test "current_id() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> Gossip.current_id(nil) end
    assert_raise FunctionClauseError, fn -> Gossip.current_id([]) end
    assert_raise FunctionClauseError, fn -> Gossip.current_id({}) end
    assert_raise FunctionClauseError, fn -> Gossip.current_id({:ok}) end
    assert_raise FunctionClauseError, fn -> Gossip.current_id({:ok, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.current_id({:ok, nil, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.current_id({:gossip, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.current_id({:gossip, nil, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.current_id({:gossip, nil, nil, nil}) end
  end

  test "current_id() get" do
    g = Gossip.new(NetID.new({127,0,0,1}, 29999), [])
    id = Gossip.current_id(g)
    assert BroadcastID.valid?(id)
    nid = BroadcastID.origin(id)
    assert nid == NetID.new({127,0,0,1}, 29999)
  end

  # seen_ids
  test "seen_ids() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> Gossip.seen_ids(nil) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_ids([]) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_ids({}) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_ids({:ok}) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_ids({:ok, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_ids({:ok, nil, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_ids({:gossip, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_ids({:gossip, nil, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_ids({:gossip, nil, nil, nil}) end

    g = Gossip.new(NetID.new({127,0,0,1}, 29999), [])
    assert_raise FunctionClauseError, fn -> Gossip.seen_ids(nil, nil) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_ids(g, nil) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_ids(g, {}) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_ids(g, {:ok}) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_ids(g, [{:ok}]) end
  end

  test "seen_ids() get and set" do
    g = Gossip.new(NetID.new({127,0,0,1}, 29999), [])
    id1 = BroadcastID.new(NetID.new({127,0,0,1}, 29998))
    id2 = BroadcastID.new(NetID.new({127,0,0,1}, 29997))
    g2 = g |> Gossip.seen_ids([id1, id2])
    assert [] == g |> Gossip.seen_ids
    assert [id1, id2] == g2 |> Gossip.seen_ids
  end

  # distribution_list
  test "distribution_list() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> Gossip.distribution_list(nil) end
    assert_raise FunctionClauseError, fn -> Gossip.distribution_list([]) end
    assert_raise FunctionClauseError, fn -> Gossip.distribution_list({}) end
    assert_raise FunctionClauseError, fn -> Gossip.distribution_list({:ok}) end
    assert_raise FunctionClauseError, fn -> Gossip.distribution_list({:ok, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.distribution_list({:ok, nil, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.distribution_list({:gossip, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.distribution_list({:gossip, nil, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.distribution_list({:gossip, nil, nil, nil}) end

    g = Gossip.new(NetID.new({127,0,0,1}, 29999), [])
    assert_raise FunctionClauseError, fn -> Gossip.distribution_list(nil, nil) end
    assert_raise FunctionClauseError, fn -> Gossip.distribution_list(g, nil) end
    assert_raise FunctionClauseError, fn -> Gossip.distribution_list(g, {}) end
    assert_raise FunctionClauseError, fn -> Gossip.distribution_list(g, {:ok}) end
    assert_raise FunctionClauseError, fn -> Gossip.distribution_list(g, [{:ok}]) end
  end

  test "distribution_list() get and set" do
    g = Gossip.new(NetID.new({127,0,0,1}, 29999), [])
    id1 = NetID.new({127,0,0,1}, 29998)
    id2 = NetID.new({127,0,0,1}, 29997)
    g2 = g |> Gossip.distribution_list([id1, id2])
    assert [] == g |> Gossip.distribution_list
    assert [id1, id2] == g2 |> Gossip.distribution_list
  end

  # remove_from_distribution_list
  test "remove_from_distribution_list throws on invalud input" do
    g = Gossip.new(NetID.new({127,0,0,1}, 29999), [])
    assert_raise FunctionClauseError, fn -> Gossip.remove_from_distribution_list(g, nil) end
    assert_raise FunctionClauseError, fn -> Gossip.remove_from_distribution_list(g, [ok: 1]) end
    assert_raise FunctionClauseError, fn -> Gossip.remove_from_distribution_list(g, {}) end
    assert_raise FunctionClauseError, fn -> Gossip.remove_from_distribution_list(g, {:ok}) end

    id = NetID.new({127,0,0,1}, 29999)
    assert_raise FunctionClauseError, fn -> Gossip.remove_from_distribution_list(nil, [id]) end
    assert_raise FunctionClauseError, fn -> Gossip.remove_from_distribution_list([ok: 1], [id]) end
    assert_raise FunctionClauseError, fn -> Gossip.remove_from_distribution_list({}, [id]) end
    assert_raise FunctionClauseError, fn -> Gossip.remove_from_distribution_list({:ok}, [id]) end

    assert_raise FunctionClauseError, fn -> Gossip.remove_from_distribution_list(nil, []) end
    assert_raise FunctionClauseError, fn -> Gossip.remove_from_distribution_list([ok: 1], []) end
    assert_raise FunctionClauseError, fn -> Gossip.remove_from_distribution_list({}, []) end
    assert_raise FunctionClauseError, fn -> Gossip.remove_from_distribution_list({:ok}, []) end
  end

  # add_to_distribution_list
  test "add_to_distribution_list throws on invalud input" do
    g = Gossip.new(NetID.new({127,0,0,1}, 29999), [])
    assert_raise FunctionClauseError, fn -> Gossip.add_to_distribution_list(g, nil) end
    assert_raise FunctionClauseError, fn -> Gossip.add_to_distribution_list(g, [ok: 1]) end
    assert_raise FunctionClauseError, fn -> Gossip.add_to_distribution_list(g, {}) end
    assert_raise FunctionClauseError, fn -> Gossip.add_to_distribution_list(g, {:ok}) end

    id = NetID.new({127,0,0,1}, 29999)
    assert_raise FunctionClauseError, fn -> Gossip.add_to_distribution_list(nil, [id]) end
    assert_raise FunctionClauseError, fn -> Gossip.add_to_distribution_list([ok: 1], [id]) end
    assert_raise FunctionClauseError, fn -> Gossip.add_to_distribution_list({}, [id]) end
    assert_raise FunctionClauseError, fn -> Gossip.add_to_distribution_list({:ok}, [id]) end

    assert_raise FunctionClauseError, fn -> Gossip.add_to_distribution_list(nil, []) end
    assert_raise FunctionClauseError, fn -> Gossip.add_to_distribution_list([ok: 1], []) end
    assert_raise FunctionClauseError, fn -> Gossip.add_to_distribution_list({}, []) end
    assert_raise FunctionClauseError, fn -> Gossip.add_to_distribution_list({:ok}, []) end
  end

  test "add and remove to/from the distribution_list" do
    g = Gossip.new(NetID.new({127,0,0,1}, 29999), [])
    id1 = NetID.new({127,0,0,1}, 29998)
    id2 = NetID.new({127,0,0,1}, 29997)
    assert [] == g |> Gossip.distribution_list
    g1 = g |> Gossip.add_to_distribution_list([id1])
    assert [id1] == g1 |> Gossip.distribution_list
    g12 = g1 |> Gossip.add_to_distribution_list([id2])
    assert [id1] == g12 |> Gossip.distribution_list |> Enum.filter(fn(x) -> x == id1 end)
    assert [id2] == g12 |> Gossip.distribution_list |> Enum.filter(fn(x) -> x == id2 end)
    gx1 = g12 |> Gossip.remove_from_distribution_list([id2])
    assert [id1] == gx1 |> Gossip.distribution_list
    gx = gx1 |> Gossip.remove_from_distribution_list([id1])
    assert [] == gx |> Gossip.distribution_list
  end

  test "add_to_distribution_list is idempotent" do
    g = Gossip.new(NetID.new({127,0,0,1}, 29999), [])
    id1 = NetID.new({127,0,0,1}, 29998)
    id2 = NetID.new({127,0,0,1}, 29997)
    g1 = g |> Gossip.add_to_distribution_list([id1])
    assert [id1] == g1 |> Gossip.distribution_list
    assert [id1] == g1 |> Gossip.add_to_distribution_list([id1]) |> Gossip.distribution_list
    g12 = g1 |> Gossip.add_to_distribution_list([id2]) |> Gossip.add_to_distribution_list([id2])
    g12 = g12 |> Gossip.add_to_distribution_list([id1]) |> Gossip.add_to_distribution_list([id1])
    assert [id1] == g12 |> Gossip.distribution_list |> Enum.filter(fn(x) -> x == id1 end)
    assert [id2] == g12 |> Gossip.distribution_list |> Enum.filter(fn(x) -> x == id2 end)
  end

  test "remove from distribution_list can be applied multiple times" do
    g = Gossip.new(NetID.new({127,0,0,1}, 29999), [])
    id1 = NetID.new({127,0,0,1}, 29998)
    id2 = NetID.new({127,0,0,1}, 29997)
    g12 = g |> Gossip.add_to_distribution_list([id1, id2])
    assert [id1] == g12 |> Gossip.distribution_list |> Enum.filter(fn(x) -> x == id1 end)
    assert [id2] == g12 |> Gossip.distribution_list |> Enum.filter(fn(x) -> x == id2 end)
    g1 = g12 |> Gossip.remove_from_distribution_list([id2]) |> Gossip.remove_from_distribution_list([id2])
    assert [id1] == g1 |> Gossip.distribution_list
    g0 = g1 |> Gossip.remove_from_distribution_list([id1]) |> Gossip.remove_from_distribution_list([id1])
    assert [] == g0 |> Gossip.distribution_list
  end

  # seen_netids
  test "seen_netids() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> Gossip.seen_netids(nil) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_netids([]) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_netids({}) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_netids({:ok}) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_netids({:ok, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_netids({:ok, nil, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_netids({:gossip, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_netids({:gossip, nil, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.seen_netids({:gossip, nil, nil, nil}) end
  end

  test "seen_netids() get and set" do
    g = Gossip.new(NetID.new({127,0,0,1}, 29999), [])
    ni1 = NetID.new({127,0,0,1}, 29998)
    ni2 = NetID.new({127,0,0,1}, 29997)
    id1 = BroadcastID.new(ni1)
    id2 = BroadcastID.new(ni2)
    g2 = g |> Gossip.seen_ids([id1, id2])
    assert [] == g |> Gossip.seen_netids
    assert [ni1] == g2 |> Gossip.seen_netids |> Enum.filter(fn(x) -> x == ni1 end)
    assert [ni2] == g2 |> Gossip.seen_netids |> Enum.filter(fn(x) -> x == ni2 end)
  end

  # payload
  test "payload() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> Gossip.payload(nil) end
    assert_raise FunctionClauseError, fn -> Gossip.payload([]) end
    assert_raise FunctionClauseError, fn -> Gossip.payload({}) end
    assert_raise FunctionClauseError, fn -> Gossip.payload({:ok}) end
    assert_raise FunctionClauseError, fn -> Gossip.payload({:ok, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.payload({:ok, nil, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.payload({:gossip, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.payload({:gossip, nil, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.payload({:gossip, nil, nil, nil}) end
  end

  test "payload() get/set" do
    g = Gossip.new(NetID.new({127,0,0,1}, 29999), []) |> Gossip.payload(:hello_world)
    assert :hello_world == Gossip.payload(g)
  end

  # extract_netids
  test "extract_netids() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> Gossip.extract_netids(nil) end
    assert_raise FunctionClauseError, fn -> Gossip.extract_netids([]) end
    assert_raise FunctionClauseError, fn -> Gossip.extract_netids({}) end
    assert_raise FunctionClauseError, fn -> Gossip.extract_netids({:ok}) end
    assert_raise FunctionClauseError, fn -> Gossip.extract_netids({:ok, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.extract_netids({:ok, nil, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.extract_netids({:gossip, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.extract_netids({:gossip, nil, nil}) end
    assert_raise FunctionClauseError, fn -> Gossip.extract_netids({:gossip, nil, nil, nil}) end
  end

  test "extract_netids() returns own id" do
    id = NetID.new({127,0,0,1}, 29999)
    g = Gossip.new(id, [])
    assert :ok  == Gossip.extract_netids(g) |> NetID.validate_list
    assert [id] == Gossip.extract_netids(g)
  end

  test "extract_netids() returns seen_ids" do
    g = Gossip.new(NetID.new({127,0,0,1}, 29999), [])
    ni1 = NetID.new({127,0,0,1}, 29998)
    ni2 = NetID.new({127,0,0,1}, 29997)
    id1 = BroadcastID.new(ni1)
    id2 = BroadcastID.new(ni2)
    g2 = g |> Gossip.seen_ids([id1, id2])
    assert [ni1] == g2 |> Gossip.extract_netids |> Enum.filter(fn(x) -> x == ni1 end)
    assert [ni2] == g2 |> Gossip.extract_netids |> Enum.filter(fn(x) -> x == ni2 end)
  end

  test "extract_netids() returns distribution_list" do
    g = Gossip.new(NetID.new({127,0,0,1}, 29999), [])
    ni1 = NetID.new({127,0,0,1}, 29998)
    ni2 = NetID.new({127,0,0,1}, 29997)
    g2 = g |> Gossip.distribution_list([ni1, ni2])
    assert [ni1] == g2 |> Gossip.extract_netids |> Enum.filter(fn(x) -> x == ni1 end)
    assert [ni2] == g2 |> Gossip.extract_netids |> Enum.filter(fn(x) -> x == ni2 end)
  end

  test "encode_with() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> Gossip.encode_with(nil, %{}) end
    assert_raise FunctionClauseError, fn -> Gossip.encode_with([], %{}) end
    assert_raise FunctionClauseError, fn -> Gossip.encode_with({}, %{}) end
    assert_raise FunctionClauseError, fn -> Gossip.encode_with({:ok}, %{}) end
    assert_raise FunctionClauseError, fn -> Gossip.encode_with({:ok, nil}, %{}) end
    assert_raise FunctionClauseError, fn -> Gossip.encode_with({:ok, nil, nil}, %{}) end
    assert_raise FunctionClauseError, fn -> Gossip.encode_with({:gossip, nil}, %{}) end
    assert_raise FunctionClauseError, fn -> Gossip.encode_with({:gossip, nil, nil}, %{}) end
    assert_raise FunctionClauseError, fn -> Gossip.encode_with({:gossip, nil, nil, nil}, %{}) end
  end

  test "encode_with() works with decode_with()" do
    g = Gossip.new(NetID.new({127,0,0,1}, 29999), [])
    ni1 = NetID.new({127,0,0,1}, 29998)
    ni2 = NetID.new({127,0,0,1}, 29997)
    id1 = BroadcastID.new(ni1)
    id2 = BroadcastID.new(ni2)

    g = g |> Gossip.distribution_list([ni1, ni2]) |> Gossip.seen_ids([id1, id2])
    ids = Gossip.extract_netids(g) |> Enum.uniq
    {_count,fwd,rev} = ids |> Enum.reduce({0, %{}, %{}}, fn(x,acc) ->
      {count, fw, re} = acc
      {count+1, Map.put(fw, x, count), Map.put(re, count, x)}
    end)

    encoded = Gossip.encode_with(g, fwd)
    {decoded, <<>>} = Gossip.decode_with(encoded, rev)
    assert Gossip.payload(decoded, []) == g
  end

  # decode_with
  test "decode_with() throws on invalid input" do
    g = Gossip.new(NetID.new({127,0,0,1}, 29999), [])
    ni1 = NetID.new({127,0,0,1}, 29998)
    ni2 = NetID.new({127,0,0,1}, 29997)
    id1 = BroadcastID.new(ni1)
    id2 = BroadcastID.new(ni2)

    g = g |> Gossip.distribution_list([ni1, ni2]) |> Gossip.seen_ids([id1, id2])
    ids = Gossip.extract_netids(g) |> Enum.uniq
    {_count, fwd, _rev} = ids |> Enum.reduce({0, %{}, %{}}, fn(x,acc) ->
      {count, fw, re} = acc
      {count+1, Map.put(fw, x, count), Map.put(re, count, x)}
    end)

    encoded = Gossip.encode_with(g, fwd)

    # check invalid map
    assert_raise KeyError, fn -> Gossip.decode_with(encoded, %{}) end
    assert_raise FunctionClauseError, fn -> Gossip.decode_with(encoded, %{0 => 0}) end
  end
end
