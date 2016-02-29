defmodule Chatter.SupervisorTest do

  use ExUnit.Case
  alias Chatter

  test "locate() returns valid pid" do
    assert is_pid(Chatter.Supervisor.locate)
    assert is_pid(Chatter.Supervisor.locate!)
  end

  # broadcast(gossip)
  # broadcast([nodes], message)
end
