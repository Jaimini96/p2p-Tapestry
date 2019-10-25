defmodule Tapestry do
  use GenServer

  def init([num_nodes, num_requests]) do
    {:ok, [num_nodes, num_requests]}
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

  def main(numNodes, max_requests \\ 1, failure_percentage) do
    GenServer.start_link(Tapestry, [numNodes, max_requests], name: Master)

    peers =
      for i <- 1..numNodes do
        name = node_name(i)
        GenServer.start_link(Peer, [i, numNodes, max_requests], name: name)
        # IO.puts(name)
        i
      end

    fail_forcefully(failure_percentage)
    datastore = :ets.new(:datastore, [:set, :public, :named_table])
    :ets.insert(datastore, {"ets_hop_count", 0})
    # IO.inspect(peers)
    for _i <- 1..max_requests do
      start_requests(peers, failure_percentage)
    end

    Process.sleep(2000)
    max_hop_count = elem(Enum.at(:ets.lookup(:datastore, "ets_hop_count"), 0), 1)
    # IO.inspect(max_hop_count)
    IO.puts("Maximum number of hops : #{max_hop_count}")
    Process.sleep(:infinity)
  end

  def fail_forcefully(percentage) do

    if percentage == 0 do
      ""
    else GenServer.cast(Master, {:goto_sleep, percentage})
    end
  end

  def handle_cast({:goto_sleep, percentage }, [num_nodes, num_requests]) do
    sleeping_nodes_count = round(num_nodes*percentage / 100)
    sleeping_nodes = Enum.take_random(Enum.to_list( 1.. num_nodes),sleeping_nodes_count)
    IO.puts("Forcefully Failed nodes: #{inspect sleeping_nodes} ")
    Enum.each sleeping_nodes, fn( node ) ->
      GenServer.cast(node_name(node),{:goto_sleep, :going_to_sleep })
    end
    {:noreply,[num_nodes, num_requests]}
  end

  def start_requests(peer_list, failure_prcnt) do
    for i <- peer_list do
      hop_count = 0
      hop_list = []
      final_target = Enum.random(peer_list)
      case failure_prcnt == 0 do
        true -> GenServer.cast(node_name(i), {:lookup, {false, hop_list, hop_count, final_target}})
        false -> GenServer.cast(node_name(i), {:lookup, {true, hop_list, hop_count, final_target}})
      end

    end
  end

  def get_hex_value(x) do
    Integer.to_string(x, 16)
  end
  def node_name(x) do
    a = x |> get_hex_value() |> String.pad_leading(8, "0")

    ("Elixir.N" <> a)
    |> String.to_atom()
  end
end
