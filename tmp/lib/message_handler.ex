defmodule Chatter.MessageHandler do

  require Record
  require Chatter.NetID
  alias Chatter.NetID

  Record.defrecord :message_handler,
                   tag: nil,
                   code: nil,
                   extract_netids: nil,
                   encode_with: nil,
                   decode_with: nil,
                   dispatch: nil

  @type t :: record( :message_handler,
                     tag: atom,
                     code: integer,
                     extract_netids: ((tuple) -> list(NetID.t)),
                     encode_with: ((tuple, map) -> binary),
                     decode_with: ((binary, map) -> {tuple, binary}),
                     dispatch: ((tuple) -> {:ok, tuple} | {:error, atom}) )

  @spec new(atom,
            ((tuple) -> list(NetID.t)),
            ((tuple, map) -> binary),
            ((binary, map) -> {tuple, binary}),
            ((tuple) -> {:ok, tuple} | {:error, atom}))  :: t
  def new(tag,
          extract_netids_fn,
          encode_with_fn,
          decode_with_fn,
          dispatch_fn)
  when is_atom(tag) and
       is_function(extract_netids_fn,1) and
       is_function(encode_with_fn,2) and
       is_function(decode_with_fn,2) and
       is_function(dispatch_fn, 1)
  do
    message_handler([tag: tag,
                     code: to_code(tag),
                     extract_netids: extract_netids_fn,
                     encode_with: encode_with_fn,
                     decode_with: decode_with_fn,
                     dispatch: dispatch_fn])
  end

  @spec new(tuple,
            ((tuple) -> list(NetID.t)),
            ((tuple, map) -> binary),
            ((binary, map) -> {tuple, binary}),
            ((tuple) -> {:ok, tuple} | {:error, atom})) :: t
  def new(tup,
          extract_netids_fn,
          encode_with_fn,
          decode_with_fn,
          dispatch_fn)
  when is_tuple(tup) and
       tuple_size(tup) > 1 and
       is_function(extract_netids_fn,1) and
       is_function(encode_with_fn,2) and
       is_function(decode_with_fn,2) and
       is_function(dispatch_fn, 1)
  do
    tag = :erlang.element(1, tup)
    message_handler([tag: tag,
                     code: to_code(tag),
                     extract_netids: extract_netids_fn,
                     encode_with: encode_with_fn,
                     decode_with: decode_with_fn,
                     dispatch: dispatch_fn])
  end

  defmacro is_valid(data) do
    case Macro.Env.in_guard?(__CALLER__) do
      true ->
        quote do
          is_tuple(unquote(data)) and tuple_size(unquote(data)) == 7 and
          :erlang.element(1, unquote(data)) == :message_handler and
          # data
          is_atom(:erlang.element(2, unquote(data))) and
          # code
          is_integer(:erlang.element(3, unquote(data))) and
          # extract_netids
          is_function(:erlang.element(4, unquote(data)),1) and
          # encode_with
          is_function(:erlang.element(5, unquote(data)),2) and
          # decode_with
          is_function(:erlang.element(6, unquote(data)),2) and
          # dispatch
          is_function(:erlang.element(7, unquote(data)),1)
        end
      false ->
        quote bind_quoted: binding() do
          is_tuple(data) and tuple_size(data) == 7 and
          :erlang.element(1, data) == :message_handler and
          # data
          is_atom(:erlang.element(2, data)) == false and
          # code
          is_integer(:erlang.element(3, data)) and
          # extract_netids
          is_function(:erlang.element(4, data),1) and
          # encode_with
          is_function(:erlang.element(5, data),2) and
          # decode_with
          is_function(:erlang.element(6, data),2) and
          # dispatch
          is_function(:erlang.element(7, data),1)
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

  @spec extract_netids(t, tuple) :: list(NetID.t)
  def extract_netids(coder, obj)
  when is_valid(coder) and
       is_tuple(obj) and
       tuple_size(obj) > 0 and
       :erlang.element(1, obj) == :erlang.element(2, coder)
  do
    fun = message_handler(coder, :extract_netids)
    fun.(obj)
  end

  @spec encode_with(t, tuple, map) :: binary
  def encode_with(coder, obj, id_map)
  when is_valid(coder) and
       is_map(id_map) and
       is_tuple(obj) and
       tuple_size(obj) > 0 and
       :erlang.element(1, obj) == :erlang.element(2, coder)
  do
    fun = message_handler(coder, :encode_with)
    fun.(obj, id_map)
  end

  @spec decode_with(t, binary, map) :: {tuple, binary}
  def decode_with(decoder, bin, id_map)
  when is_valid(decoder) and
       is_binary(bin) and
       byte_size(bin) > 0 and
       is_map(id_map)
  do
    fun = message_handler(decoder, :decode_with)
    fun.(bin, id_map)
  end

  @spec dispatch(t, tuple) :: {:ok, tuple} | {:error | atom}
  def dispatch(dispatcher, msg)
  when is_valid(dispatcher) and
       is_tuple(msg) and
       tuple_size(msg) > 1
  do
    fun = message_handler(dispatcher, :dispatch)
    fun.(msg)
  end

  @spec to_code(atom) :: integer
  def to_code(id)
  when is_atom(id)
  do
    to_string(id) |> :xxhash.hash32
  end

  def to_code(tuple)
  when is_tuple(tuple) and
       tuple_size(tuple) > 1
  do
    :erlang.element(1, tuple) |> to_code
  end
end
