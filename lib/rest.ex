defmodule RestPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/json")
    |> put_resp_header("Access-Control-Allow-Origin", "*")
    |> send_resp(200, Poison.encode!(
    	JSONSchema.schema_and_form(TestWorld.Demo)
    ))
  end
end
