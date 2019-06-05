defmodule JSONSchema.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: RestPlug, options: [port: 3000]}
    ]

    opts = [strategy: :one_for_one, name: JSONSchema.Supervisor]

    Logger.info("Starting application...")

    Agent.start_link(fn -> nil end, name: Slackbridge)

    Supervisor.start_link(children, opts)
  end
end
