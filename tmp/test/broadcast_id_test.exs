defmodule Chatter.BroadcastIDTest do

  use ExUnit.Case
  alias Chatter.NetID
  alias Chatter.BroadcastID

  defp dummy_me do
    NetID.new({1,2,3,4},1)
  end

  defp dummy_other do
    NetID.new({2,3,4,5},2)
  end

  defp dummy_third do
    NetID.new({3,4,5,6},3)
  end

  defp dummy_list do
    [dummy_me, dummy_other, dummy_third]
  end

  defp dummy_bc_list do
    dummy_list |> Enum.reduce([], fn(x,acc) ->
      [BroadcastID.new(x,123457678) | acc]
    end)
  end

  test "basic test for new" do
    assert BroadcastID.valid?(BroadcastID.new(NetID.new({127,0,0,1}, 29999)))
  end

  test "basic test for invalid input" do
    assert BroadcastID.valid?(nil) == false
    assert BroadcastID.valid?([]) == false
    assert BroadcastID.valid?({}) == false
    assert BroadcastID.valid?(:ok) == false
    assert BroadcastID.valid?({:ok}) == false
    assert BroadcastID.valid?({:broadcast_id}) == false
    assert BroadcastID.valid?({:broadcast_id, nil}) == false
    assert BroadcastID.valid?({:broadcast_id, nil, nil}) == false
    assert BroadcastID.valid?({:broadcast_id, nil, nil, nil}) == false
  end

  # origin
  test "origin() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> BroadcastID.origin(nil) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin([]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin({}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin({:ok}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin({:ok, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin({:ok, nil, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin({:broadcast_id, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin({:broadcast_id, nil, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin({:broadcast_id, nil, nil, nil}) end

    id = BroadcastID.new(NetID.new({127,0,0,1}, 29999))
    assert_raise FunctionClauseError, fn -> BroadcastID.origin(nil, nil) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin(id, nil) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin(id, []) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin(id, {}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin(id, {:ok}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin(id, {:ok, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin(id, {:ok, nil, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin(id, {:net_id, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin(id, {:net_id, nil, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.origin(id, {:net_id, nil, nil, nil}) end
  end

  test "origin() get and set" do
    id = BroadcastID.new(NetID.new({127,0,0,1}, 29999))
    nid = NetID.new({127,0,0,1}, 29998)
    v = id |> BroadcastID.origin(nid)
    assert id != v
    assert nid == BroadcastID.origin(v)
  end

  # seqno
  test "seqno() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno(nil) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno([]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno({}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno({:ok}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno({:ok, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno({:ok, nil, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno({:broadcast_id, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno({:broadcast_id, nil, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno({:broadcast_id, nil, nil, nil}) end

    id = BroadcastID.new(NetID.new({127,0,0,1}, 29999))
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno(nil, nil) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno(id, nil) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno(id, []) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno(id, {}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno(id, {:ok}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno(id, {:ok, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno(id, {:ok, nil, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno(id, {:net_id, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno(id, {:net_id, nil, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.seqno(id, {:net_id, nil, nil, nil}) end
  end

  test "seqno() get and set" do
    id = BroadcastID.new(NetID.new({127,0,0,1}, 29999))
    v = id |> BroadcastID.seqno(111)
    assert id != v
    assert 111 == BroadcastID.seqno(v)
  end

  # validate_list!
  test "validate_list!() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> BroadcastID.validate_list!(nil) end
    assert_raise FunctionClauseError, fn -> BroadcastID.validate_list!({}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.validate_list!({:ok}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.validate_list!({:ok, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.validate_list!({:ok, nil, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.validate_list!({:broadcast_id, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.validate_list!({:broadcast_id, nil, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.validate_list!({:broadcast_id, nil, nil, nil}) end

    assert_raise FunctionClauseError, fn -> BroadcastID.validate_list!([{}]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.validate_list!([{:ok}]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.validate_list!([{:ok, nil}]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.validate_list!([{:ok, nil, nil}]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.validate_list!([{:broadcast_id, nil}]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.validate_list!([{:broadcast_id, nil, nil}]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.validate_list!([{:broadcast_id, nil, nil, nil}]) end
  end

  test "validate_list!([]) is :ok" do
    assert :ok == BroadcastID.validate_list!([])
  end

  # merge_lists
  test "merge_lists() throws on invalid input" do
    id = BroadcastID.new(NetID.new({127,0,0,1}, 29999))

    assert_raise FunctionClauseError, fn -> BroadcastID.merge_lists([{}], [id]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.merge_lists([{:ok}], [id]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.merge_lists([{:ok, nil}], [id]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.merge_lists([{:ok, nil, nil}], [id]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.merge_lists([{:broadcast_id, nil}], [id]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.merge_lists([{:broadcast_id, nil, nil}], [id]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.merge_lists([{:broadcast_id, nil, nil, nil}], [id]) end

    assert_raise FunctionClauseError, fn -> BroadcastID.merge_lists([id], [{}]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.merge_lists([id], [{:ok}]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.merge_lists([id], [{:ok, nil}]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.merge_lists([id], [{:ok, nil, nil}]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.merge_lists([id], [{:broadcast_id, nil}]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.merge_lists([id], [{:broadcast_id, nil, nil}]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.merge_lists([id], [{:broadcast_id, nil, nil, nil}]) end
  end

  test "merge_list([], []) is []" do
    assert [] == BroadcastID.merge_lists([], [])
  end

  test "merge_list([x], []) is [x]" do
    id = BroadcastID.new(NetID.new({127,0,0,1}, 29999))
    assert [id] == BroadcastID.merge_lists([id], [])
  end

  test "merge_list([], [x]) is [x]" do
    id = BroadcastID.new(NetID.new({127,0,0,1}, 29999))
    assert [id] == BroadcastID.merge_lists([], [id])
  end

  test "merge_list([x], [x]) is [x]" do
    id = BroadcastID.new(NetID.new({127,0,0,1}, 29999))
    assert [id] == BroadcastID.merge_lists([id], [id])
  end

  test "merge_list([x, x], [x, x]) is [x]" do
    id = BroadcastID.new(NetID.new({127,0,0,1}, 29999))
    assert [id] == BroadcastID.merge_lists([id, id], [id, id])
  end

  test "merge_list([x, x+1], [x, x]) is [x+1]" do
    id = BroadcastID.new(NetID.new({127,0,0,1}, 29999))
    id2 = id |> BroadcastID.seqno( BroadcastID.seqno(id) + 1)
    assert id != id2
    assert [^id2] = BroadcastID.merge_lists([id, id2], [id, id])
    assert (BroadcastID.seqno(id) + 1) == BroadcastID.seqno(id2)
  end

  # inc_seqno
  test "inc_seqno() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> BroadcastID.inc_seqno(nil) end
    assert_raise FunctionClauseError, fn -> BroadcastID.inc_seqno([]) end
    assert_raise FunctionClauseError, fn -> BroadcastID.inc_seqno({}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.inc_seqno({:ok}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.inc_seqno({:ok, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.inc_seqno({:ok, nil, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.inc_seqno({:broadcast_id, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.inc_seqno({:broadcast_id, nil, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.inc_seqno({:broadcast_id, nil, nil, nil}) end
  end

  test "inc_seqno() bumps the sequence number" do
    id = BroadcastID.new(NetID.new({127,0,0,1}, 29999))
    id2 = BroadcastID.inc_seqno(id)
    assert (BroadcastID.seqno(id)+1) == BroadcastID.seqno(id2)
  end

  # validate_list
  test "validate_list() returns :error on invalid input" do
    assert :error = BroadcastID.validate_list({})
    assert :error = BroadcastID.validate_list({:ok})
    assert :error = BroadcastID.validate_list({:ok, nil})
    assert :error = BroadcastID.validate_list({:ok, nil, nil})
    assert :error = BroadcastID.validate_list({:broadcast_id, nil})
    assert :error = BroadcastID.validate_list({:broadcast_id, nil, nil})
    assert :error = BroadcastID.validate_list({:broadcast_id, nil, nil, nil})

    assert :error = BroadcastID.validate_list([{}])
    assert :error = BroadcastID.validate_list([{:ok}])
    assert :error = BroadcastID.validate_list([{:ok, nil}])
    assert :error = BroadcastID.validate_list([{:ok, nil, nil}])
    assert :error = BroadcastID.validate_list([{:broadcast_id, nil}])
    assert :error = BroadcastID.validate_list([{:broadcast_id, nil, nil}])
    assert :error = BroadcastID.validate_list([{:broadcast_id, nil, nil, nil}])
  end

  test "validate_list([]) is :ok" do
    assert :ok == BroadcastID.validate_list([])
  end

  test "basic test for new(netid,seqno)" do
    assert BroadcastID.valid?(BroadcastID.new(NetID.new({127,0,0,1}, 29999), 111))
  end

  # new(netid, seqno)
  test "new(netid, seqno) throws on invalid input" do
    d = NetID.new({127,0,0,1}, 29999)
    assert_raise FunctionClauseError, fn -> BroadcastID.new(nil, nil) end
    assert_raise FunctionClauseError, fn -> BroadcastID.new(d, nil) end
    assert_raise FunctionClauseError, fn -> BroadcastID.new(d, -1) end
    assert_raise FunctionClauseError, fn -> BroadcastID.new(d, []) end
    assert_raise FunctionClauseError, fn -> BroadcastID.new(d, {}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.new(d, {:ok}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.new(d, {:ok, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.new(d, {:ok, nil, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.new(d, {:peer_data, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.new(d, {:peer_data, nil, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.new(d, {:peer_data, nil, nil, nil}) end
  end

  # encode_with
  test "encode_with() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> BroadcastID.encode_with(nil, %{}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.encode_with([], %{}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.encode_with({}, %{}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.encode_with({:ok}, %{}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.encode_with({:ok, nil}, %{}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.encode_with({:ok, nil, nil}, %{}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.encode_with({:broadcast_id, nil}, %{}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.encode_with({:broadcast_id, nil, nil}, %{}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.encode_with({:broadcast_id, nil, nil, nil}, %{}) end
  end

  test "decode_with() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> BroadcastID.decode_with(<<>>, nil) end
    assert_raise FunctionClauseError, fn -> BroadcastID.decode_with(<<>>, []) end
    assert_raise FunctionClauseError, fn -> BroadcastID.decode_with(<<>>, {}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.decode_with(<<>>, {:ok}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.decode_with(<<>>, {:ok, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.decode_with(<<>>, {:ok, nil, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.decode_with(<<>>, {:broadcast_id, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.decode_with(<<>>, {:broadcast_id, nil, nil}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.decode_with(<<>>, {:broadcast_id, nil, nil, nil}) end
  end

  test "encode_with() works with decode_with()" do
    fwd = %{dummy_me => 0}
    rev = %{0 => dummy_me}
    id = BroadcastID.new(dummy_me, 123456)
    encoded = BroadcastID.encode_with(id, fwd)
    {decoded, <<>>} = BroadcastID.decode_with(encoded, rev)
    assert decoded == id

    # check bad inputs
    assert_raise KeyError, fn -> BroadcastID.decode_with(encoded, %{}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.decode_with(encoded, %{0 => 0}) end
  end

  # encode_list_with
  test "encode_list_with() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> BroadcastID.encode_list_with(<<>>, %{dummy_me => 0}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.encode_list_with({}, %{dummy_me => 0}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.encode_list_with([{:ok}], %{dummy_me => 0}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.encode_list_with([:ok], %{dummy_me => 0}) end
  end

  # decode_list_with
  test "decode_list_with() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> BroadcastID.decode_list_with(<<>>, %{}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.decode_list_with({}, %{}) end
    assert_raise FunctionClauseError, fn -> BroadcastID.decode_list_with(:ok, %{}) end
  end

  test "encode_list_with() works with decode_list_with()" do
    {_count, fwd, rev} = dummy_list |> Enum.reduce({0, %{}, %{}}, fn(x,acc) ->
      {count, fw, re} = acc
      {count+1, Map.put(fw, x, count), Map.put(re, count, x)}
    end)
    encoded = BroadcastID.encode_list_with(dummy_bc_list, fwd)
    {decoded, <<>>} = BroadcastID.decode_list_with(encoded, rev)

    assert decoded == dummy_bc_list
  end
end
