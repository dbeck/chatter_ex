defmodule Chatter.NetID do

  require Record
  alias Chatter.Serializer

  Record.defrecord :net_id,
                   ip: nil,
                   port: 0

  @type t :: record( :net_id,
                     ip: tuple,
                     port: integer )

  defmacro is_valid_port(data) do
    case Macro.Env.in_guard?(__CALLER__) do
      true ->
        quote do
          is_integer(unquote(data)) and
          unquote(data) >= 0 and
          unquote(data) <= 0xffff
        end
      false ->
        quote bind_quoted: binding() do
          is_integer(data) and
          data >= 0 and
          data <= 0xffff
        end
    end
  end

  defmacro is_valid_ip(ip) do
    case Macro.Env.in_guard?(__CALLER__) do
      true ->
        quote do
          is_tuple(unquote(ip)) and
          tuple_size(unquote(ip)) == 4 and
          is_integer(:erlang.element(1,unquote(ip))) and
          is_integer(:erlang.element(2,unquote(ip))) and
          is_integer(:erlang.element(3,unquote(ip))) and
          is_integer(:erlang.element(4,unquote(ip))) and
          :erlang.element(1,unquote(ip)) >= 0 and
          :erlang.element(2,unquote(ip)) >= 0 and
          :erlang.element(3,unquote(ip)) >= 0 and
          :erlang.element(4,unquote(ip)) >= 0 and
          :erlang.element(1,unquote(ip)) < 256 and
          :erlang.element(2,unquote(ip)) < 256 and
          :erlang.element(3,unquote(ip)) < 256 and
          :erlang.element(4,unquote(ip)) < 256
        end
      false ->
        quote bind_quoted: binding() do
          is_tuple(ip) and
          tuple_size(ip) == 4 and
          is_integer(:erlang.element(1,ip)) and
          is_integer(:erlang.element(2,ip)) and
          is_integer(:erlang.element(3,ip)) and
          is_integer(:erlang.element(4,ip)) and
          :erlang.element(1,ip) >= 0 and
          :erlang.element(2,ip) >= 0 and
          :erlang.element(3,ip) >= 0 and
          :erlang.element(4,ip) >= 0 and
          :erlang.element(1,ip) < 256 and
          :erlang.element(2,ip) < 256 and
          :erlang.element(3,ip) < 256 and
          :erlang.element(4,ip) < 256
        end
    end
  end

  @spec new(tuple, integer) :: t
  def new(ip, port)
  # TODO : IPV6
  when is_valid_ip(ip) and
       is_valid_port(port)
  do
    net_id(ip: ip) |> net_id(port: port)
  end

  defmacro is_valid(data) do
    case Macro.Env.in_guard?(__CALLER__) do
      true ->
        quote do
          is_tuple(unquote(data)) and tuple_size(unquote(data)) == 3 and
          :erlang.element(1, unquote(data)) == :net_id and
          # ip
          # TODO : IPV6
          is_tuple(:erlang.element(2, unquote(data))) and
          tuple_size(:erlang.element(2, unquote(data))) == 4 and
          # port
          is_integer(:erlang.element(3, unquote(data))) and
          :erlang.element(3, unquote(data)) >= 0 and
          :erlang.element(3, unquote(data)) <= 0xffff
        end
      false ->
        quote bind_quoted: binding() do
          is_tuple(data) and tuple_size(data) == 3 and
          :erlang.element(1, data) == :net_id and
          # ip
          # TODO : IPV6
          is_tuple(:erlang.element(2, data)) and
          tuple_size(:erlang.element(2, data)) == 4 and
          # port
          is_integer(:erlang.element(3, data)) and
          :erlang.element(3, data) >= 0 and
          :erlang.element(3, data) <= 0xffff
        end
    end
  end

  @spec valid?(t) :: boolean
  def valid?(data)
  when is_valid(data)
  do
    true
  end

  def valid?(_), do: false

  @spec validate_list(list(t)) :: :ok | :error
  def validate_list([]), do: :ok

  def validate_list([head|rest])
  do
    case valid?(head) do
      true -> validate_list(rest)
      false -> :error
    end
  end

  @spec validate_list!(list(t)) :: :ok
  def validate_list!([]), do: :ok

  def validate_list!([head|rest])
  when is_valid(head)
  do
    validate_list!(rest)
  end

  @spec ip(t) :: tuple
  def ip(id)
  when is_valid(id)
  do
    net_id(id, :ip)
  end

  @spec port(t) :: integer
  def port(id)
  when is_valid(id)
  do
    net_id(id, :port)
  end

  @spec encode(t) :: binary
  def encode(id)
  when is_valid(id)
  do
    {ip1, ip2, ip3, ip4} = net_id(id, :ip)
    << ip1 :: size(8), ip2 :: size(8), ip3 :: size(8), ip4 :: size(8), net_id(id, :port) :: big-size(16) >>
  end

  @spec encode_list(list(t)) :: binary
  def encode_list(ids)
  when is_list(ids)
  do
    List.foldl(ids, Serializer.encode_uint(length(ids)), fn(id, acc) ->
      acc <> encode(id)
    end)
  end

  @spec encode_list_with(list(t), map) :: binary
  def encode_list_with(ids, id_map)
  when is_list(ids) and
       is_map(id_map)
  do
    :ok = validate_list!(ids)
    bin_size  = ids |> length |> Serializer.encode_uint
    bin_list  = ids |> Enum.reduce(<<>>, fn(x,acc) ->
      id = Map.fetch!(id_map, x)
      acc <> Serializer.encode_uint(id)
    end)
    << bin_size :: binary,
       bin_list :: binary >>
  end

  @spec decode(binary) :: {t, binary}
  def decode(<< ip1 :: size(8), ip2 :: size(8), ip3 :: size(8), ip4 :: size(8), port :: big-size(16) >>)
  when is_valid_port(port) and
       is_valid_ip({ip1, ip2, ip3, ip4})
  do
    {net_id(ip: {ip1, ip2, ip3, ip4}) |> net_id(port: port), <<>>}
  end

  def decode(<< ip1 :: size(8), ip2 :: size(8), ip3 :: size(8), ip4 :: size(8), port :: big-size(16), remaining :: binary >>)
  when is_valid_port(port) and
       is_valid_ip({ip1, ip2, ip3, ip4})
  do
    {net_id(ip: {ip1, ip2, ip3, ip4}) |> net_id(port: port), remaining}
  end

  @spec decode_list(binary) :: {list(t), binary}
  def decode_list(bin)
  do
    {count, remaining} = Serializer.decode_uint(bin)
    {list, remaining} = decode_list_(remaining, count, [])
    {Enum.reverse(list), remaining}
  end

  defp decode_list_(<<>>, _count, acc), do: {acc, <<>>}
  defp decode_list_(binary, 0, acc), do: {acc, binary}

  defp decode_list_(msg, count, acc)
  when is_binary(msg) and
       is_integer(count) and
       count > 0 and
       is_list(acc)
  do
    {id, remaining} = decode(msg)
    decode_list_(remaining, count-1, [id | acc])
  end

  @spec decode_list_with(binary, map) :: {list(t), binary}
  def decode_list_with(bin, id_map)
  do
    {count, remaining} = Serializer.decode_uint(bin)
    {list, remaining} = decode_list_with_(remaining, count, [], id_map)
    {Enum.reverse(list), remaining}
  end

  defp decode_list_with_(<<>>, _count, acc, _map), do: {acc, <<>>}
  defp decode_list_with_(binary, 0, acc, _map), do: {acc, binary}

  defp decode_list_with_(msg, count, acc, map)
  when is_binary(msg) and
       is_integer(count) and
       count > 0 and
       is_list(acc) and
       is_map(map)
  do
    {id, remaining} = Serializer.decode_uint(msg)
    netid = Map.fetch!(map, id)
    decode_list_with_(remaining, count-1, [netid | acc], map)
  end
end
