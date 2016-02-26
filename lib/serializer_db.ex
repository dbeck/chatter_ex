defmodule Chatter.SerializerDB do

  use ExActor.GenServer
  require Chatter.EncoderDecoder
  alias Chatter.EncoderDecoder

  defstart start_link([], opts),
    gen_server_opts: opts
  do
    name = Keyword.get(opts, :name, id_atom())
    table = :ets.new(name, [:named_table, :set, :protected, {:keypos, 3}])
    initial_state(table)
  end

  # Convenience API

  def add(pid, encdec)
  when is_pid(pid) and
       EncoderDecoder.is_valid(encdec)
  do
    GenServer.cast(pid, {:add, encdec})
  end

  def get(pid, obj)
  when is_pid(pid) and
       is_tuple(obj) and
       tuple_size(obj) > 1
  do
  	get(pid, EncoderDecoder.to_code(obj))
  end

  def get(pid, tag)
  when is_pid(pid) and
       is_atom(tag)
  do
  	get(pid, EncoderDecoder.to_code(tag))
  end

  def get(pid, code)
  when is_pid(pid) and
       is_integer(code)
  do
    GenServer.call(pid, {:get, code})
  end

  # Direct, read-only ETS access
  # note: since the writer process may be slower than the readers
  #       the direct readers may not see the immediate result of the
  #       writes

  def get_(obj)
  when is_tuple(obj) and
       tuple_size(obj) > 1
  do
  	EncoderDecoder.to_code(obj) |> get_
  end

  def get_(tag)
  when is_atom(tag)
  do
  	EncoderDecoder.to_code(tag) |> get_
  end

  def get_(code)
  when is_integer(code)
  do
    name = id_atom()
    case :ets.lookup(name, code)
    do
      []      -> {:error, :not_found}
      [value] -> {:ok, value}
    end
  end

  # GenServer

  defcast stop, do: stop_server(:normal)

  def handle_cast({:add, encdec}, table)
  when EncoderDecoder.is_valid(encdec)
  do
    :ets.insert_new(table, encdec)
    {:noreply, table}
  end

  def handle_call({:get, code}, _from, table)
  when is_integer(code)
  do
    case :ets.lookup(table, code)
    do
      []      -> {:reply, :error, table}
      [value] -> {:reply, {:ok, value}, table}
    end
  end

  def locate, do: Process.whereis(id_atom())

  def locate! do
    case Process.whereis(id_atom()) do
      pid when is_pid(pid) ->
        pid
    end
  end

  def id_atom, do: __MODULE__
end
