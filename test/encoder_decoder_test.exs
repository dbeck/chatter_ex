defmodule Chatter.EncoderDecoderTest do

  use ExUnit.Case
  alias Chatter.EncoderDecoder
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
    EncoderDecoder.new(:erlang.element(1,id), extract_fn, encode_fn, decode_fn)
  end

  test "basic test for new" do
    assert EncoderDecoder.valid?(dummy_serializable)
  end

end
