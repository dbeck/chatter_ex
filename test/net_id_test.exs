defmodule Chatter.NetIDTest do

  use ExUnit.Case
  alias Chatter.NetID

  test "basic test for new" do
    assert NetID.valid?(NetID.new({127,0,0,1}, 29999))
  end

  test "basic test for invalid input" do
    assert NetID.valid?(nil) == false
    assert NetID.valid?([]) == false
    assert NetID.valid?({}) == false
    assert NetID.valid?(:ok) == false
    assert NetID.valid?({:ok}) == false
    assert NetID.valid?({:net_id}) == false
    assert NetID.valid?({:net_id, nil}) == false
    assert NetID.valid?({:net_id, nil, nil}) == false
    assert NetID.valid?({:net_id, nil, nil, nil}) == false
  end

  test "validate valid list" do
    id1 = NetID.new({127,0,0,1}, 29999)
    id2 = NetID.new({127,0,0,1}, 29998)
    id3 = NetID.new({127,0,0,1}, 29997)

    assert NetID.validate_list([]) == :ok
    assert NetID.validate_list([id1]) == :ok
    assert NetID.validate_list([id1, id2, id3]) == :ok
  end

  test "validate bad net_id list" do
    id1 = NetID.new({127,0,0,1}, 29999)
    id2 = NetID.new({127,0,0,1}, 29998)
    id3 = NetID.new({127,0,0,1}, 29997)

    assert NetID.validate_list([:ok]) == :error
    assert NetID.validate_list([{:net_id}]) == :error
    assert NetID.validate_list([id1, :ok]) == :error
    assert NetID.validate_list([:ok, id1]) == :error
    assert NetID.validate_list([id1, :error, id2, id3]) == :error
    assert NetID.validate_list([id1, id2, {:net_id}, id3]) == :error
    assert NetID.validate_list([id1, id2, id3, :ok]) == :error
    assert NetID.validate_list([id1, id2, id3, {:net_id}]) == :error
  end

  # validate_list!
  test "validate!() valid list" do
    id1 = NetID.new({127,0,0,1}, 29999)
    id2 = NetID.new({127,0,0,1}, 29998)
    id3 = NetID.new({127,0,0,1}, 29997)

    assert NetID.validate_list!([]) == :ok
    assert NetID.validate_list!([id1]) == :ok
    assert NetID.validate_list!([id1, id2, id3]) == :ok
  end

  test "validate!() bad net_id list" do
    id1 = NetID.new({127,0,0,1}, 29999)
    id2 = NetID.new({127,0,0,1}, 29998)
    id3 = NetID.new({127,0,0,1}, 29997)

    assert_raise FunctionClauseError, fn -> NetID.validate_list!([:ok]) end
    assert_raise FunctionClauseError, fn -> NetID.validate_list!([{:net_id}]) end
    assert_raise FunctionClauseError, fn -> NetID.validate_list!([id1, :ok]) end
    assert_raise FunctionClauseError, fn -> NetID.validate_list!([:ok, id1]) end
    assert_raise FunctionClauseError, fn -> NetID.validate_list!([id1, :error, id2, id3]) end
    assert_raise FunctionClauseError, fn -> NetID.validate_list!([id1, id2, {:net_id}, id3]) end
    assert_raise FunctionClauseError, fn -> NetID.validate_list!([id1, id2, id3, :ok]) end
    assert_raise FunctionClauseError, fn -> NetID.validate_list!([id1, id2, id3, {:net_id}]) end
  end

  # ip
  test "ip() raises on invalid invalid input" do
    assert_raise FunctionClauseError, fn -> NetID.ip(nil) end
    assert_raise FunctionClauseError, fn -> NetID.ip([]) end
    assert_raise FunctionClauseError, fn -> NetID.ip({}) end
    assert_raise FunctionClauseError, fn -> NetID.ip(:ok) end
    assert_raise FunctionClauseError, fn -> NetID.ip({:ok}) end
    assert_raise FunctionClauseError, fn -> NetID.ip({:net_id}) end
    assert_raise FunctionClauseError, fn -> NetID.ip({:net_id, nil}) end
    assert_raise FunctionClauseError, fn -> NetID.ip({:net_id, nil, nil}) end
    assert_raise FunctionClauseError, fn -> NetID.ip({:net_id, nil, nil, nil}) end
  end

  # port
  test "port() raises on invalid invalid input" do
    assert_raise FunctionClauseError, fn -> NetID.port(nil) end
    assert_raise FunctionClauseError, fn -> NetID.port([]) end
    assert_raise FunctionClauseError, fn -> NetID.port({}) end
    assert_raise FunctionClauseError, fn -> NetID.port(:ok) end
    assert_raise FunctionClauseError, fn -> NetID.port({:ok}) end
    assert_raise FunctionClauseError, fn -> NetID.port({:net_id}) end
    assert_raise FunctionClauseError, fn -> NetID.port({:net_id, nil}) end
    assert_raise FunctionClauseError, fn -> NetID.port({:net_id, nil, nil}) end
    assert_raise FunctionClauseError, fn -> NetID.port({:net_id, nil, nil, nil}) end
  end

  # encode
  test "encode() raises on invalid invalid input" do
    assert_raise FunctionClauseError, fn -> NetID.encode(nil) end
    assert_raise FunctionClauseError, fn -> NetID.encode([]) end
    assert_raise FunctionClauseError, fn -> NetID.encode({}) end
    assert_raise FunctionClauseError, fn -> NetID.encode(:ok) end
    assert_raise FunctionClauseError, fn -> NetID.encode({:ok}) end
    assert_raise FunctionClauseError, fn -> NetID.encode({:net_id}) end
    assert_raise FunctionClauseError, fn -> NetID.encode({:net_id, nil}) end
    assert_raise FunctionClauseError, fn -> NetID.encode({:net_id, nil, nil}) end
    assert_raise FunctionClauseError, fn -> NetID.encode({:net_id, nil, nil, nil}) end
  end

  test "encode() works with decode()" do
    encoded = NetID.encode(dummy_me)
    {decoded, <<>>} = NetID.decode(encoded)
    assert dummy_me == decoded

    # decode fails on empty input
    assert_raise FunctionClauseError, fn -> NetID.decode(<<>>) end
  end

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

  test "encode_list() fails on invalid input" do
    assert_raise FunctionClauseError, fn -> NetID.encode_list({}) end
    assert_raise FunctionClauseError, fn -> NetID.encode_list({:ok}) end
    assert_raise FunctionClauseError, fn -> NetID.encode_list(:ok) end
    assert_raise FunctionClauseError, fn -> NetID.encode_list(dummy_list ++ [:ok]) end
  end

  test "encode_list() works with decode_list()" do
    encoded = NetID.encode_list(dummy_list)
    {decoded, <<>>} = NetID.decode_list(encoded)

    assert decoded == dummy_list

    # decode_list fails on invalid input
    assert_raise MatchError, fn -> NetID.decode_list(<<255>>) end
  end

  test "encode_list_with() works with decode_list_with()" do
    {_count, fwd, rev} = dummy_list |> Enum.reduce({0, %{}, %{}}, fn(x,acc) ->
      {count, fw, re} = acc
      {count+1, Map.put(fw, x, count), Map.put(re, count, x)}
    end)

    encoded = NetID.encode_list_with(dummy_list, fwd)
    {decoded, <<>>} = NetID.decode_list_with(encoded, rev)

    assert dummy_list == decoded

    # encode fails on invalid input
    assert_raise FunctionClauseError, fn -> NetID.encode_list_with(dummy_list ++ [:ok], fwd) end
    assert_raise KeyError, fn -> NetID.encode_list_with(dummy_list, %{}) end
    assert_raise KeyError, fn -> NetID.encode_list_with(dummy_list, %{0 => 0}) end

    # decode fails on invalid input
    assert_raise KeyError, fn -> NetID.decode_list_with(encoded, %{}) end
    assert_raise KeyError, fn -> NetID.decode_list_with(encoded, %{0 => 0}) end
  end
end
