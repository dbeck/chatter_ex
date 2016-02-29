use Mix.Config

config :chatter,
  my_addr: System.get_env("GROUP_MANAGER_ADDRESS") || "127.0.0.1",
  my_port: System.get_env("GROUP_MANAGER_PORT") || "29999",
  multicast_addr: System.get_env("GROUP_MANAGER_MULTICAST_ADDRESS") || "224.1.1.1",
  multicast_port: System.get_env("GROUP_MANAGER_MULTICAST_PORT") || "29999",
  multicast_ttl: System.get_env("GROUP_MANAGER_MULTICAST_TTL") || "4",
  key: System.get_env("GROUP_MANAGER_KEY") || "01234567890123456789012345678912"
