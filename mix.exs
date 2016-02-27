defmodule Chatter.Mixfile do
  use Mix.Project

  def project do
    [
      app: :chatter,
      version: "0.0.6",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.1",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
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
end
