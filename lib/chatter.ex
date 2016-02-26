defmodule Chatter do

  use Application
  require Logger
  require Chatter.NetID
  alias Chatter.NetID

  def start(_type, args)
  do
    :random.seed(:os.timestamp)
    Chatter.Supervisor.start_link(args)
  end

    def get_local_ip
  do
    {:ok, list} = :inet.getif
    [{ip, _broadcast, _netmask}] = list
    |> Enum.filter( fn({_ip, bcast, _nm}) -> bcast != :undefined end)
    |> Enum.take(1)
    ip
  end

  def local_netid
  do
    # try to figure our local IP if not given
    case Application.fetch_env(:chatter, :my_addr) do
      {:ok, nil} ->
        my_addr = get_local_ip()
      {:ok, my_addr_str} ->
        {:ok, my_addr} = my_addr_str |> String.to_char_list |> :inet_parse.address
      _ ->
        my_addr = get_local_ip()
    end

    my_port = case Application.fetch_env(:chatter, :my_port)
    do
      {:ok, val} ->
        {my_port, ""} = val |> Integer.parse
        my_port
      :error ->
        Logger.info "no my_port config value found for group_manager Application [default: 29999]"
        29999
    end
    NetID.new(my_addr, my_port)
  end

  def multicast_netid
  do
    mcast_addr_str = case Application.fetch_env(:chatter, :multicast_addr)
    do
      {:ok, val} ->
        val
      :error ->
        Logger.info "no multicast_addr config value found for group_manager Application [default: 224.1.1.1]"
        "224.1.1.1"
    end

    mcast_port_str = case Application.fetch_env(:chatter, :multicast_port)
    do
      {:ok, val} ->
        val
      :error ->
        Logger.info "no multicast_port config value found for group_manager Application [default: 29999]"
        "29999"
    end

    {:ok, multicast_addr} = mcast_addr_str |> String.to_char_list |> :inet_parse.address
    {multicast_port, ""}  = mcast_port_str |> Integer.parse

    NetID.new(multicast_addr, multicast_port)
  end

  def multicast_ttl
  do
    case Application.fetch_env(:chatter, :multicast_ttl)
    do
      {:ok, mcast_ttl_str} ->
        {multicast_ttl, ""}   = mcast_ttl_str  |> Integer.parse
        multicast_ttl
      :error ->
        Logger.info "no multicast_ttl config value found for group_manager Application [default: 4]"
        4
    end
  end

  def group_manager_key
  do
    case Application.fetch_env(:chatter, :key)
    do
      {:ok, key} when is_binary(key) and byte_size(key) == 32->
        key

      :error ->
        Logger.error "no 'key' config value found for group_manager Application"
        "01234567890123456789012345678901"

      {:ok, key} ->
        Logger.error "'key' has to be 32 bytes long for group_manager Application"
        << retval :: binary-size(32), _rest :: binary  >> = key <> "01234567890123456789012345678901"
        retval
    end
  end

end
