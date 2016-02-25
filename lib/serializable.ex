defmodule Chatter.Serializable do

  require Record
  require Chatter.NetID
  alias Chatter.NetID
  #alias Chatter.Serializer

  Record.defrecord :serializable,
                   data: nil,
                   extract_netids: nil,
                   encode_with: nil,
                   decode_with: nil

  @type t :: record( :serializable,
                     data: any,
                     extract_netids: (any) -> list(NetID.t),
                     encode_with: (any, map) -> binary,
                     decode_with: (binary, map) -> {any, binary})

  def new()
  do
    :error
  end

end
