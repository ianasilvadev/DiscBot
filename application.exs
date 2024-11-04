defmodule KpopBot.Application do

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KpopBot
    ]
    opts = [strategy: :one_for_one, name: KpopBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
