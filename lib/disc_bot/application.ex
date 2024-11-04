defmodule DiscBot.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DiscBot  # Aqui estamos adicionando o nosso bot como um filho do supervisor
    ]

    opts = [strategy: :one_for_one, name: DiscBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
