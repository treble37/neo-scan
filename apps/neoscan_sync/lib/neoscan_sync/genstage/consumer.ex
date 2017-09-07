defmodule NeoscanSync.Consumer do
  use GenStage
  alias Neoscan.Blocks
  alias Neoscan.Transactions

  def start_link do
    GenStage.start_link(__MODULE__, :state_doesnt_matter, name: __MODULE__)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [{NeoscanSync.Producer, max_demand: 200, min_demand: 100}]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      add_block(event)
    end

    # As a consumer we never emit events
    {:noreply, [], state}
  end

   #add block with transactions to the db
  defp add_block(%{"tx" => transactions, "index" => height} = block) do
    Map.put(block,"tx_count",Kernel.length(transactions))
    |> Map.delete("tx")
    |> Blocks.create_block()
    |> Transactions.create_transactions(transactions)
    |> check(height)
  end

  defp check(r, height) do
    cond do
      {:ok, "Created"} == r or {:ok, "Deleted"} == r ->
        IO.puts("Block #{height} stored")
      true ->
        IO.puts("Failed to create transactions")
        Blocks.get_block_by_height(height)
        |> Blocks.delete_block()
    end
  end

end
