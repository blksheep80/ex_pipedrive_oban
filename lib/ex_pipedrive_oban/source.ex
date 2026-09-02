defmodule ExPipedriveOban.Source do
  @moduledoc """
  Host callbacks for building a client and persisting each synced page.
  """

  @type args :: map()

  @callback client(args()) ::
              Tesla.Client.t() | {:ok, Tesla.Client.t()} | {:error, term()}

  @callback handle_page(resource :: String.t(), [term()], args()) :: :ok | {:error, term()}
end
