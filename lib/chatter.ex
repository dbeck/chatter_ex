defmodule Chatter do
  use Application

  def start(_type, args)
  do
    :random.seed(:os.timestamp)
    GroupManager.Supervisor.start_link(args)
  end
end
