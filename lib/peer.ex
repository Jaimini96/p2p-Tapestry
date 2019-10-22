defmodule Peer do
  use GenServer

  def init([id, max_nodes, num_requests]) do
    neighbors = get_neighbors(id, max_nodes)
    # IO.inspect neighbors
    # numRequests, keys, id, neighbors, target, hop_count, hop_list, source
    {:ok, %{num_requests: num_requests, keys: [], id: id, neighbors: neighbors, hop_count: 0, hop_list: [], source: 0}}
  end

  def get_neighbors(id, max_nodes) do
    lvl1 = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000]
    d4 = div(id , 1000)
    d3 = div(id , 100)
    d2 = div(id , 10)

    lvl2 = [
      d4 * 1000 + 100,
      d4 * 1000 + 200,
      d4 * 1000 + 300,
      d4 * 1000 + 400,
      d4 * 1000 + 500,
      d4 * 1000 + 600,
      d4 * 1000 + 700,
      d4 * 1000 + 800,
      d4 * 1000 + 900
    ]


    lvl3 = [
      d3 * 100 + 10,
      d3 * 100 + 20,
      d3 * 100 + 30,
      d3 * 100 + 40,
      d3 * 100 + 50,
      d3 * 100 + 60,
      d3 * 100 + 70,
      d3 * 100 + 80,
      d3 * 100 + 90
    ]

    lvl4 = [
      d2 * 10 + 1,
      d2 * 10 + 2,
      d2 * 10 + 3,
      d2 * 10 + 4,
      d2 * 10 + 5,
      d2 * 10 + 6,
      d2 * 10 + 7,
      d2 * 10 + 8,
      d2 * 10 + 9
    ]
    full_list = lvl1 ++ lvl2 ++ lvl3 ++ lvl4 ++ [1]
    uniq = Enum.uniq(full_list)
    Enum.filter(uniq, fn(x) -> x<max_nodes && x != id end)
  end

  def handle_cast({:lookup, {hop_count,final_target}}, state) do
    neighbors = state.neighbors

    if state.id == final_target do
      ets_count = elem(Enum.at(:ets.lookup(:datastore, "ets_hop_count"),0),1)
      #IO.inspect(new_hop_count)
      if hop_count > ets_count do
        # :ets.update_counter(:datastore, "ets_hop_count", {2,hop_count})
        :ets.insert(:datastore, {"ets_hop_count", hop_count})
      end
      # IO.puts ("id: #{state.id},  hop_count: #{hop_count}")
      # System.halt(1)
      #TODO send hop_count to Master server
    else
      next_target = find_next_target(neighbors, final_target)
      # IO.inspect next_target
      GenServer.cast(node_name(next_target), {:lookup, {hop_count + 1, final_target}})
    end
    {:noreply, state}
  end

  # def find_next_target_test() do
  #   list = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 8100, 8200, 8300, 8400, 8500,
  #   8600, 8700, 8800, 8900, 8910, 8920, 8930, 8940, 8950, 8960, 8970, 8980, 8990,
  #   8991, 8992, 8993, 8995, 8996, 8997, 8998, 8999, 1]
  #   final_target = 8954
  #   Enum.min_by list, fn i ->
  #     if i <= final_target do
  #       final_target - i
  #     end
  #   end
  # end

  def find_next_target(list, final_target) do
    Enum.min_by list, fn i ->
      if i <= final_target do
        final_target - i
      end
    end
  end

  def node_name(x) do
    a = x |> Integer.to_string() |> String.pad_leading(4, "0")

    ("Elixir.N" <> a)
    |> String.to_atom()
  end
end
