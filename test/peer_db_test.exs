defmodule GroupManager.Chatter.PeerDBTest do

  use ExUnit.Case
  alias GroupManager.Chatter.PeerDB
  alias GroupManager.Chatter.PeerData
  alias Common.NetID
  alias Common.BroadcastID

  test "locate PeerDB" do
    pid = PeerDB.locate
    assert is_pid(pid)
  end

  test "cannot add() invalid" do
    pid = PeerDB.locate
    assert_raise FunctionClauseError, fn -> PeerDB.add(pid, nil) end
  end

  test "can add() valid NetID" do
    pid = PeerDB.locate
    id = NetID.new({127,0,0,1}, 29999)
    assert :ok == PeerDB.add(pid, id)
  end

  test "can add() and get()/get_() valid NetID" do
    pid = PeerDB.locate
    id = NetID.new({127,0,0,1}, 29919)
    assert :ok == PeerDB.add(pid, id)
    # {:ok, {:peer_data, {:net_id, {127, 0, 0, 1}, 29999}, 0, [], nil, nil}}
    assert {:ok, _} = PeerDB.get(pid, id)
    assert {:ok, _} = PeerDB.get_(id)
  end

  test "get() and get_ raises on invalid id" do
    pid = PeerDB.locate
    assert_raise FunctionClauseError, fn -> PeerDB.get(pid, nil) end
    assert_raise FunctionClauseError, fn -> PeerDB.get(pid, []) end
    assert_raise FunctionClauseError, fn -> PeerDB.get(pid, {}) end

    assert_raise FunctionClauseError, fn -> PeerDB.get_(nil) end
    assert_raise FunctionClauseError, fn -> PeerDB.get_([]) end
    assert_raise FunctionClauseError, fn -> PeerDB.get_({}) end
  end

  # add_seen_id
  test "add_seen_id() raises on invalid id" do
    pid = PeerDB.locate
    assert_raise FunctionClauseError, fn -> PeerDB.add_seen_id(pid, nil, nil) end
    assert_raise FunctionClauseError, fn -> PeerDB.add_seen_id(pid, :ok, {}) end
  end

  # add_seen_id_list
  test "add_seen_id_list() raises on invalid id" do
    pid = PeerDB.locate
    assert_raise FunctionClauseError, fn -> PeerDB.add_seen_id_list(pid, nil, nil) end
    assert_raise FunctionClauseError, fn -> PeerDB.add_seen_id_list(pid, :ok, []) end
  end

  test "add_seen_id_list() adds ids" do
    pid  = PeerDB.locate
    id1  = BroadcastID.new(NetID.new({127,0,0,1}, 29991))
    id2  = BroadcastID.new(NetID.new({127,0,0,1}, 29992))
    id3  = BroadcastID.new(NetID.new({127,0,0,1}, 29993))
    id4  = BroadcastID.new(NetID.new({127,0,0,1}, 29994))
    PeerDB.add_seen_id_list(pid, id1, [id2, id3, id4])
    assert {:ok, _} = PeerDB.get(pid, BroadcastID.origin(id1))
    id1  = BroadcastID.inc_seqno(id1)
    id2  = BroadcastID.inc_seqno(id2)
    id3  = BroadcastID.inc_seqno(id3)
    id4  = BroadcastID.inc_seqno(id4)
    PeerDB.add_seen_id_list(pid, id1, [id2, id3, id4])
    assert {:ok, new_peer_data} = PeerDB.get(pid, BroadcastID.origin(id1))
    check_id = fn(list, id) ->
      List.foldl(list, nil, fn(x, acc) ->
        case x do
          ^id -> id
          _ -> acc
        end
      end)
    end

    assert id2 == check_id.(PeerData.seen_ids(new_peer_data), id2)
    assert id3 == check_id.(PeerData.seen_ids(new_peer_data), id3)
    assert id4 == check_id.(PeerData.seen_ids(new_peer_data), id4)
    assert PeerData.id(new_peer_data) == BroadcastID.origin(id1)
    assert PeerData.broadcast_seqno(new_peer_data) == BroadcastID.seqno(id1)
  end

  # get_seen_id_list_
  test "get_seen_id_list_() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> PeerDB.get_seen_id_list_(nil) end
    assert_raise FunctionClauseError, fn -> PeerDB.get_seen_id_list_([]) end
    assert_raise FunctionClauseError, fn -> PeerDB.get_seen_id_list_({}) end
  end

  test "get_seen_id_list_() returns the seen ids" do
    pid  = PeerDB.locate
    id1  = BroadcastID.new(NetID.new({127,0,0,1}, 29971))
    id2  = BroadcastID.new(NetID.new({127,0,0,1}, 29972))
    id3  = BroadcastID.new(NetID.new({127,0,0,1}, 29973))
    id4  = BroadcastID.new(NetID.new({127,0,0,1}, 29974))
    assert :ok == PeerDB.add_seen_id_list(pid, id1, [id2, id3, id4])
    assert {:ok, _} = PeerDB.get(pid, BroadcastID.origin(id1))
    assert {:ok, _} = PeerDB.get_(BroadcastID.origin(id1))
    {:ok, ids} = PeerDB.get_seen_id_list_(id1 |> BroadcastID.origin)
    assert id2 == Enum.find(ids, fn(x) -> x == id2 end)
    assert id3 == Enum.find(ids, fn(x) -> x == id3 end)
    assert id4 == Enum.find(ids, fn(x) -> x == id4 end)
  end

  # get_broadcast_seqno_
  test "get_broadcast_seqno_() throws on invalid input" do
    assert_raise FunctionClauseError, fn -> PeerDB.get_broadcast_seqno_(nil) end
    assert_raise FunctionClauseError, fn -> PeerDB.get_broadcast_seqno_([]) end
    assert_raise FunctionClauseError, fn -> PeerDB.get_broadcast_seqno_({}) end
  end

  test "get_broadcast_seqno_() returns the valid seqno" do
    pid  = PeerDB.locate
    id1  = BroadcastID.new(NetID.new({127,0,0,1}, 29961))
    id2  = BroadcastID.new(NetID.new({127,0,0,1}, 29962))
    assert :ok == PeerDB.add_seen_id(pid, id1, id2)
    assert {:ok, peer_data1} = PeerDB.get(pid, BroadcastID.origin(id1))
    assert {:ok, peer_data2} = PeerDB.get(pid, BroadcastID.origin(id2))
    assert PeerData.id(peer_data1) == BroadcastID.origin(id1)
    assert PeerData.id(peer_data2) == BroadcastID.origin(id2)
    assert {:ok, PeerData.broadcast_seqno(peer_data1)} ==
      PeerDB.get_broadcast_seqno_(BroadcastID.origin(id1))
    assert {:ok, PeerData.broadcast_seqno(peer_data2)} ==
      PeerDB.get_broadcast_seqno_(BroadcastID.origin(id2))
  end

  # inc_broadcast_seqno
  test "inc_broadcast_seqno() throws on invalid input" do
    pid = PeerDB.locate
    assert_raise FunctionClauseError, fn -> PeerDB.inc_broadcast_seqno(pid, nil) end
    assert_raise FunctionClauseError, fn -> PeerDB.inc_broadcast_seqno(pid, []) end
    assert_raise FunctionClauseError, fn -> PeerDB.inc_broadcast_seqno(pid, {}) end
    id = NetID.new({127,0,0,1}, 29951)

    assert_raise FunctionClauseError, fn -> PeerDB.inc_broadcast_seqno(nil, id) end
    assert_raise FunctionClauseError, fn -> PeerDB.inc_broadcast_seqno([], id) end
    assert_raise FunctionClauseError, fn -> PeerDB.inc_broadcast_seqno({}, id) end
  end

  test "inc_broadcast_seqno() increases broadcast sequence number" do
    pid = PeerDB.locate
    id = NetID.new({127,0,0,1}, 29941)
    {:ok, seqno1} = PeerDB.inc_broadcast_seqno(pid, id)
    {:ok, seqno2} = PeerDB.inc_broadcast_seqno(pid, id)
    assert seqno2 == (seqno1+1)
    assert {:ok, seqno2} == PeerDB.get_broadcast_seqno_(id)
  end
end
