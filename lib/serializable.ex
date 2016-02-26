defmodule Chatter.Serializable do

  require Record
  require Chatter.NetID
  alias Chatter.NetID

  Record.defrecord :serializable,
                   data: nil,
                   extract_netids: nil,
                   encode_with: nil,
                   decode_with: nil

  @type t :: record( :serializable,
                     data: any,
                     extract_netids: ((any) -> list(NetID.t)),
                     encode_with: ((any, map) -> binary),
                     decode_with: ((binary, map) -> {any, binary}) )

  @spec new(any, any, any, any) :: t
  def new(data, extract_netids_fn, encode_with_fn, decode_with_fn)
  do
    serializable([data: data,
                  extract_netids: extract_netids_fn,
                  encode_with: encode_with_fn,
                  decode_with: decode_with_fn])
  end

  defmacro is_valid(data) do
    case Macro.Env.in_guard?(__CALLER__) do
      true ->
        quote do
          is_tuple(unquote(data)) and tuple_size(unquote(data)) == 5 and
          :erlang.element(1, unquote(data)) == :serializable and
          # data
          is_nil(:erlang.element(2, unquote(data))) == false and
          is_tuple(:erlang.element(2, unquote(data))) and
          # extract_netids
          is_function(:erlang.element(3, unquote(data)),1) and
          # encode_with
          is_function(:erlang.element(4, unquote(data)),2) and
          # decode_with
          is_function(:erlang.element(5, unquote(data)),2)
        end
      false ->
        quote bind_quoted: binding() do
          is_tuple(data) and tuple_size(data) == 5 and
          :erlang.element(1, data) == :serializable and
          # data
          is_nil(:erlang.element(2, data)) == false and
          is_tuple(:erlang.element(2, data)) and
          # extract_netids
          is_function(:erlang.element(3, data),1) and
          # encode_with
          is_function(:erlang.element(4, data),2) and
          # decode_with
          is_function(:erlang.element(5, data),2)
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

  @spec extract_netids(t) :: list(NetID.t)
  def extract_netids(ser)
  when is_valid(ser)
  do
    fun = serializable(ser, :extract_netids)
    fun.(serializable(ser, :data))
  end

  @spec encode_with(t, map) :: binary
  def encode_with(ser, id_map)
  when is_valid(ser) and
       is_map(id_map)
  do
    fun = serializable(ser, :encode_with)
    fun.(serializable(ser, :data), id_map)
  end

  @spec decode_with(t, binary, map) :: {any, binary}
  def decode_with(ser, bin, id_map)
  when is_valid(ser) and
       is_binary(bin) and
       byte_size(bin) > 0 and
       is_map(id_map)
  do
    fun = serializable(ser, :decode_with)
    fun.(serializable(bin, :data), id_map)
  end
end
