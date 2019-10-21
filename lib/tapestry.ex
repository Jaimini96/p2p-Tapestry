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
        IO.puts(name)
        i
      end

    IO.inspect(peers)
    Process.sleep(:infinity)
  end

  def node_name(x) do
    a = x |> Integer.to_string() |> String.pad_leading(4, "0")

    ("Elixir.N" <> a)
    |> String.to_atom()
  end
end
