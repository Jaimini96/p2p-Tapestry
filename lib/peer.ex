defmodule Peer do
  use GenServer

  def init([id, num_requests]) do
    # numRequests, keys, id, neighbors, target, hop_count, hop_list, source
    {:ok, [num_requests, [], id, [], 0, 0, [], 0]}
  end

  # def create(num_nodes, num_requests) do
  #   for i <- 0..num_nodes do
  #     GenServer.start_link(Peer, [i, num_requests], name: i)
  #   end
  # end
end
