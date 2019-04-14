defmodule RestPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/json")
    |> send_resp(200, Poison.encode!(JSONSchema.schema(TestWorld.User)))
  end
end
