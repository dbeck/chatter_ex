defmodule ChatterTest do

  use ExUnit.Case
  alias Chatter.NetID

  test "get_local_ip() returns valid NetID" do
    assert is_tuple(Chatter.get_local_ip)
  end

  test "local_netid() returns valid NetID" do
    assert NetID.valid?(Chatter.local_netid)
  end

  test "multicast_netid() returns valid NetID" do
    assert NetID.valid?(Chatter.multicast_netid)
  end

  # multicast_ttl
  # group_manager_key
end
