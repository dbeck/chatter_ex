defmodule Chatter.MessageHandlerTest do

  use ExUnit.Case
  alias Chatter.MessageHandler
  alias Chatter.NetID
  alias Chatter.BroadcastID

  defp dummy_me do
    NetID.new({1,2,3,4},1)
  end

  defp dummy_serializable do
    id = BroadcastID.new(dummy_me, 111)
    extract_fn  = fn(id) -> BroadcastID.extract_netids(id) end
    encode_fn   = fn(id, ids) -> BroadcastID.encode_with(id, ids) end
    decode_fn   = fn(bin, ids) -> BroadcastID.decode_with(bin, ids) end
    dispatch_fn = fn(id) -> {:ok, id} end
    MessageHandler.new(id,
                       extract_fn,
                       encode_fn,
                       decode_fn,
                       dispatch_fn)
  end

  test "basic test for new" do
    assert MessageHandler.valid?(dummy_serializable)
  end

  # new
  # valid?
  # extract_netids
  # encode_with
  # decode_with
  # to_code(tuple)
  # to_code(atom)

end
