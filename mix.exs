defmodule DiscBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :DiscBot,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {DiscBot.Application, []}
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.8"},  # Para fazer requisições HTTP
      {:jason, "~> 1.2"},      # Para lidar com JSON
      {:nostrum, "~> 0.8"}    # Biblioteca para criar o bot no Discord

    ]
  end

end
