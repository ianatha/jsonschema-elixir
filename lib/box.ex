defmodule Box do
  defmacro __using__(_env) do
    quote do
      import Box
    end
  end

  defmacro defbox(name, attrs \\ []) do
    keys = Keyword.keys(attrs)

    quote do
      defmodule unquote(name) do
        @derive [Poison.Encoder]
        @enforce_keys unquote(keys)
        defstruct unquote(keys)

        @type t :: %__MODULE__{
                unquote_splicing(attrs)
              }
      end
    end
  end
end
