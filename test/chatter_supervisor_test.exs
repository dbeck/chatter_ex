defmodule GroupManager.ChatterTest do
  use ExUnit.Case
  require Common.NetID
  alias GroupManager.Chatter
  alias Common.NetID

  test "locate() returns valid pid" do
    assert is_pid(Chatter.locate)
    assert is_pid(Chatter.locate!)
  end

  test "get_local_ip() returns valid NetID" do
    assert is_tuple(Chatter.get_local_ip)
  end

  test "local_netid() returns valid NetID" do
    assert NetID.valid?(Chatter.local_netid)
  end

  test "multicast_netid() returns valid NetID" do
    assert NetID.valid?(Chatter.multicast_netid)
  end

  # broadcast(gossip)
  # broadcast([nodes], message)
end
