defmodule Chatter.Mixfile do
  use Mix.Project

  def project do
    [
      app: :chatter,
      version: "0.0.15",
      elixir: "~> 1.1",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description,
      package: package,
      deps: deps
    ]
  end

  def application do
    [applications: [:logger, :xxhash, :ranch],
     mod: {Chatter, []}]
  end

  defp deps do
    [
      {:snappy, "~> 1.1"},
      {:xxhash, git: "https://github.com/pierresforge/erlang-xxhash"},
      {:exactor, "~> 2.2"},
      {:ranch, "~> 1.2"}
    ]
  end

  defp description do
    """
    Chatter is extracted from the ScaleSmall project as a standalone piece.
    This may be used independently to broadcast messages to a set of nodes.
    It uses a mixture of UDP multicast and TCP to deliver messages and tries
    to minimize network traffic while doing so.
    """
  end

  defp package do
    [
     files: ["lib", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["David Beck"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/dbeck/chatter_ex/",
              "Docs" => "https://github.com/dbeck/chatter_ex/tree/master/docs"}]
  end
end
