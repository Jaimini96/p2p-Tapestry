defmodule Peer do
  use GenServer

  def init([id, max_nodes, num_requests]) do
    neighbors = get_neighbors(id, max_nodes)
    IO.inspect neighbors
    # numRequests, keys, id, neighbors, target, hop_count, hop_list, source
    {:ok, [num_requests, [], id, neighbors, 0, 0, [], 0]}
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
end
