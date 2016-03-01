defmodule Chatter.Serializer do

  require Logger
  require Chatter.Gossip
  require Chatter.BroadcastID
  require Chatter.NetID
  require Chatter.MessageHandler
  require Chatter.SerializerDB
  alias Chatter.Gossip
  alias Chatter.NetID
  alias Chatter.MessageHandler
  alias Chatter.SerializerDB

  @spec encode(Gossip.t, binary) :: binary
  def encode(gossip, key)
  when Gossip.is_valid(gossip) and
       is_binary(key) and
       byte_size(key) == 32
  do
    encoded = encode_gossip(gossip)
    cksum   = :xxhash.hash32(encoded)

    {:ok, compressed} = :snappy.compress(encoded)

    to_encrypt = <<
       :rand.uniform(0xffff_ffff_ffff_ffff) :: size(64),
       :rand.uniform(0xffff_ffff_ffff_ffff) :: size(64),
       :rand.uniform(0xffff_ffff_ffff_ffff) :: size(64),
       :rand.uniform(0xffff_ffff_ffff_ffff) :: size(64),
       cksum :: size(32),
       compressed :: binary
    >>

    {_new_state, encrypted} = :crypto.stream_init(:aes_ctr, key, "-- ScaleSmall --")
    |> :crypto.stream_encrypt(to_encrypt)

    << 0xff :: size(8), encrypted :: binary >>
  end

  @spec decode(binary, binary) :: {:ok, Gossip.t} | {:error, :invalid_data, integer}
  def decode(<< 0xff :: size(8), encrypted :: binary >>, key)
  when byte_size(encrypted) > 36 and
       is_binary(key) and
       byte_size(key) == 32
  do
    {_new_state, decrypted} = :crypto.stream_init(:aes_ctr, key, "-- ScaleSmall --")
    |> :crypto.stream_decrypt(encrypted)

    << _ :: size(64), _ :: size(64), _ :: size(64), _ :: size(64),
       cksum :: size(32),
       msg :: binary >> = decrypted

    case :snappy.decompress(msg)
    do
      {:error, :data_not_compressed} ->
        cond do
          cksum != :xxhash.hash32(msg) ->
            Logger.error "invalid data, cksum mismatch"
            {:error, :invalid_data, :cksum_error_not_compressed}

          true ->
            {gossip, _remaining} = decode_gossip(msg)
            if Gossip.valid?(gossip)
            do
              {:ok, gossip}
            else
              Logger.error "invalid data, Gossip not valid"
              {:error, :invalid_data, :failed_to_decode_uncompressed}
            end
        end

      {:ok, decomp} ->
        cond do
          cksum != :xxhash.hash32(decomp) ->
            Logger.error "invalid data, cksum mismatch"
            {:error, :invalid_data, :cksum_error}

          true ->
            {gossip, _remaining} = decode_gossip(decomp)
            if Gossip.valid?(gossip)
            do
              {:ok, gossip}
            else
              Logger.error "invalid data, Gossip not valid"
              {:error, :invalid_data, :failed_to_decode}
            end
        end

      {:error, :corrupted_data} ->
        Logger.error "invalid data, currupted data, cannot decompress"
        {:error, :invalid_data, :corrupted_data}
    end
  end

  @spec encode_gossip(Gossip.t) :: binary
  def encode_gossip(gossip)
  when Gossip.is_valid(gossip)
  do
    payload = Gossip.payload(gossip)
    ids = (extract_netids(gossip) ++ extract_netids(payload))
    |> Enum.uniq
    id_table = NetID.encode_list(ids)
    {_count, id_map} = ids |> Enum.reduce({0, %{}}, fn(x,acc) ->
      {count, m} = acc
      {count+1, Map.put(m, x, count)}
    end)

    encoded_gossip  = encode_with(gossip, id_map)
    encoded_tag     = MessageHandler.to_code(payload) |> encode_uint
    encoded_message = encode_with(payload, id_map)

    << id_table :: binary,
       encoded_gossip :: binary,
       encoded_tag :: binary,
       encoded_message :: binary >>
  end

  @spec decode_gossip(binary) :: {Gossip.t, binary}
  def decode_gossip(msg)
  when is_binary(msg) and
       byte_size(msg) > 0
  do
    {id_list, remaining} = NetID.decode_list(msg)

    {_count, id_map} = id_list |> Enum.reduce({0, %{}}, fn(x, acc) ->
      {count, m} = acc
      {count+1, Map.put(m, count, x)}
    end)

    {decoded_gossip,  remaining}  = Gossip.decode_with(remaining, id_map)
    {decoded_tag,     remaining}  = decode_uint(remaining)
    {decoded_message, remaining}  = decode_with(remaining, decoded_tag, id_map)

    { Gossip.payload_relaxed(decoded_gossip, decoded_message), remaining }
  end

  @spec encode_uint(integer) :: binary
  def encode_uint(i)
  when is_integer(i) and i >= 0
  do
    encode_uint_(<<>>, i)
  end

  @spec decode_uint(binary) :: {integer, binary}
  def decode_uint(b)
  when is_binary(b) and
       byte_size(b) > 0
  do
    decode_uint_(b, 0, 1)
  end

  defp encode_uint_(binstr, val)
  when val >= 128
  do
    encode_uint_(<< binstr :: binary, 1 :: size(1), rem(val, 128) :: size(7) >>, div(val, 128))
  end

  defp encode_uint_(binstr, val)
  when val < 128
  do
    << binstr :: binary, 0 :: size(1), val :: size(7) >>
  end

  defp decode_uint_(<< 1 :: size(1), act :: size(7), remaining :: binary>>, val, scale)
  do
    decode_uint_(remaining, val + (act*scale), scale*128)
  end

  defp decode_uint_(<< 0 :: size(1), act :: size(7)>>, val, scale)
  do
    {val + (act*scale), <<>>}
  end

  defp decode_uint_(<< 0 :: size(1), act :: size(7), remaining :: binary>>, val, scale)
  do
    {val + (act*scale), remaining}
  end

  defp decode_uint_(<<>>, val, _scale), do: val

  defp extract_netids(gossip)
  when Gossip.is_valid(gossip)
  do
    Gossip.extract_netids(gossip)
  end

  defp extract_netids(obj)
  when is_tuple(obj) and
       tuple_size(obj) > 1
  do
    case SerializerDB.get_(obj)
    do
      {:ok, extractor} ->
        MessageHandler.extract_netids(extractor, obj)
      other_value ->
        {:error, :invalid_extractor, other_value}
    end
  end

  defp encode_with(gossip, id_map)
  when Gossip.is_valid(gossip) and
       is_map(id_map)
  do
    Gossip.encode_with(gossip, id_map)
  end

  defp encode_with(obj, id_map)
  when is_tuple(obj) and
       tuple_size(obj) > 1 and
       is_map(id_map)
  do
    case SerializerDB.get_(obj)
    do
      {:ok, encoder} ->
        MessageHandler.encode_with(encoder, obj, id_map)
      other_value ->
        {:error, :invalid_encoder, other_value}
    end
  end

  defp decode_with(bin, tag, id_map)
  when is_binary(bin) and
       is_integer(tag) and
       is_map(id_map)
  do
    case SerializerDB.get_(tag)
    do
      {:ok, decoder} ->
        MessageHandler.decode_with(decoder, bin, id_map)
      other_value ->
        {:error, :invalid_decoder, other_value}
    end
  end
end
