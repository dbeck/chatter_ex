defmodule Chatter.EncoderDecoder do

  require Record
  require Chatter.NetID
  alias Chatter.NetID

  Record.defrecord :encoder_decoder,
                   tag: nil,
                   code: nil,
                   extract_netids: nil,
                   encode_with: nil,
                   decode_with: nil

  @type t :: record( :encoder_decoder,
                     tag: atom,
                     code: integer,
                     extract_netids: ((any) -> list(NetID.t)),
                     encode_with: ((any, map) -> binary),
                     decode_with: ((binary, map) -> {any, binary}) )

  @spec new(any, any, any, any) :: t
  def new(tag, extract_netids_fn, encode_with_fn, decode_with_fn)
  when is_atom(tag) and
       is_function(extract_netids_fn,1) and
       is_function(encode_with_fn,2) and
       is_function(decode_with_fn,2)
  do
    encoder_decoder([tag: tag,
                     code: to_code(tag),
                     extract_netids: extract_netids_fn,
                     encode_with: encode_with_fn,
                     decode_with: decode_with_fn])
  end

  defmacro is_valid(data) do
    case Macro.Env.in_guard?(__CALLER__) do
      true ->
        quote do
          is_tuple(unquote(data)) and tuple_size(unquote(data)) == 6 and
          :erlang.element(1, unquote(data)) == :encoder_decoder and
          # data
          is_atom(:erlang.element(2, unquote(data))) and
          # code
          is_integer(:erlang.element(3, unquote(data))) and
          # extract_netids
          is_function(:erlang.element(4, unquote(data)),1) and
          # encode_with
          is_function(:erlang.element(5, unquote(data)),2) and
          # decode_with
          is_function(:erlang.element(6, unquote(data)),2)
        end
      false ->
        quote bind_quoted: binding() do
          is_tuple(data) and tuple_size(data) == 6 and
          :erlang.element(1, data) == :encoder_decoder and
          # data
          is_atom(:erlang.element(2, data)) == false and
          # code
          is_integer(:erlang.element(3, data)) and
          # extract_netids
          is_function(:erlang.element(4, data),1) and
          # encode_with
          is_function(:erlang.element(5, data),2) and
          # decode_with
          is_function(:erlang.element(6, data),2)
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
    fun = encoder_decoder(coder, :extract_netids)
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
    fun = encoder_decoder(coder, :encode_with)
    fun.(obj, id_map)
  end

  @spec decode_with(t, binary, map) :: {any, binary}
  def decode_with(decoder, bin, id_map)
  when is_valid(decoder) and
       is_binary(bin) and
       byte_size(bin) > 0 and
       is_map(id_map)
  do
    fun = encoder_decoder(decoder, :decode_with)
    fun.(bin, id_map)
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
