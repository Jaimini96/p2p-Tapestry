defmodule Tapestry do
  use GenServer

  def init([num_nodes, num_requests]) do
    {:ok, {num_nodes, num_requests}}
  end

  def main(args) do
    [numNodes, max_requests, failure_percentage] =
      case length(args) do
        2 ->
          [numNodes1, max_requests1] = args
          {numNodes1, _} = Integer.parse(numNodes1)
          {max_requests1, _} = Integer.parse(max_requests1)
          [numNodes1, max_requests1, 0]

        3 ->
          [numNodes2, max_requests2, failure_percentage2] = args
          {numNodes2, _} = Integer.parse(numNodes2)
          {max_requests2, _} = Integer.parse(max_requests2)
          {failure_percentage2, _} = Integer.parse(failure_percentage2)
          [numNodes2, max_requests2, failure_percentage2]

        _ ->
          IO.puts("Please recheck your arguments")
      end

    main(numNodes, max_requests, failure_percentage)
  end

  def main(numNodes, max_requests \\ 1, _failure_percentage) do
    GenServer.start_link(Tapestry, [numNodes, max_requests], name: Master)

    peers =
      for i <- 1..numNodes do
        name = node_name(i)
        GenServer.start_link(Peer, [i, numNodes, max_requests], name: name)
        # IO.puts(name)
        i
      end

    datastore = :ets.new(:datastore, [:set, :public, :named_table])
    :ets.insert(datastore, {"ets_hop_count",0})
    # IO.inspect(peers)
    for _i <- 1..max_requests do
      start_requests(peers)
    end
    ets_count = elem(Enum.at(:ets.lookup(:datastore, "ets_hop_count"),0),1)
    IO.inspect ets_count
    Process.sleep(:infinity)
  end

  def start_requests(peer_list) do
    for i <- peer_list do
      hop_count = 0
      # hop_list = []
      final_target = Enum.random(peer_list)
      GenServer.cast(node_name(i), {:lookup, {hop_count,final_target}})
    end
  end
  def node_name(x) do
    a = x |> Integer.to_string() |> String.pad_leading(4, "0")

    ("Elixir.N" <> a)
    |> String.to_atom()
  end
end
