defmodule Peer do
  use GenServer

  def init([id, max_nodes, num_requests]) do
    neighbors = get_neighbors(id, max_nodes)
    # IO.inspect neighbors
    # numRequests, keys, id, neighbors, target, hop_count, hop_list, source
    {:ok,
     %{
       status: Active,
       num_requests: num_requests,
       keys: [],
       id: id,
       neighbors: neighbors,
       hop_count: 0,
       hop_list: [],
       source: 0,
       max_nodes_count: max_nodes
     }}
  end

  def get_neighbors(id, _max_nodes) do
    lvl1 = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000]
    d4 = div(id, 1000)
    d3 = div(id, 100)
    d2 = div(id, 10)

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
    Enum.filter(uniq, fn x -> x != id end)
  end

  def handle_cast({:goto_sleep, _}, state) do
    updated_state = Map.put(state, :status, Inactive)
    {:noreply, updated_state}
  end

  def handle_cast({:lookup, {is_failure, hop_list, hop_count, final_target}}, state) do
    neighbors = state.neighbors

    id = state.id
    max = state.max_nodes_count

    if state.id == final_target do
      ets_count = elem(Enum.at(:ets.lookup(:datastore, "ets_hop_count"), 0), 1)
      # hop_list2 = [node_name(state.id) | hop_list]
      # IO.inspect([node_name(final_target) | hop_list2], charlists: :as_lists)
      # IO.puts ("hopCnt: #{hop_count}")

      if hop_count > ets_count do
        # :ets.update_counter(:datastore, "ets_hop_count", {2,hop_count})
        :ets.insert(:datastore, {"ets_hop_count", hop_count})
      end

      # IO.puts ("id: #{state.id},  hop_count: #{hop_count}")
      # System.halt(1)
      # TODO send hop_count to Master server
    else
      next_target = find_next_target(neighbors, final_target)
      # IO.puts("crnt : #{id}, nextTgt: #{next_target}, finalTgt: #{final_target} ")
      # test = Active

      case is_failure do
        false ->
          # IO.puts "came"
          GenServer.cast(
            node_name(next_target),
            {:lookup, {is_failure, [node_name(state.id) | hop_list], hop_count + 1, final_target}}
          )

        true ->
          isActive = GenServer.call(node_name(next_target), :is_active, :infinity)
          # IO.inspect(isActive)

          case isActive do
            Active ->
              # IO.puts "crnt : #{state.id}, nTgt : #{next_target}, fTgt: #{final_target}"
              GenServer.cast(
                node_name(next_target),
                {:lookup, {is_failure, [node_name(state.id) | hop_list], hop_count + 1, final_target}}
              )

            Inactive ->
              case next_in_line(next_target, max) == id do
                true ->
                  # IO.puts("came to true")
                  ""

                false ->
                  # IO.puts("came")
                  # hop_list2 = [node_name(state.id) | hop_list]
                  # IO.inspect([node_name(final_target) | hop_list2], charlists: :as_lists)
                  next_active_target = get_next_active(next_target, state.id, max, final_target)

                  # IO.puts(
                  #   "nxtTgt: #{next_target}, nxtActvTgt: #{next_active_target}, finalTgt #{
                  #     final_target
                  #   }"
                  # )

                  case next_active_target == 0 do
                    true ->
                      ""

                    false ->
                      GenServer.cast(
                        node_name(next_active_target),
                        {:lookup, {is_failure, [node_name(state.id) | hop_list], hop_count + 1, final_target}}
                      )
                  end
              end
          end
      end
    end

    {:noreply, state}
  end

  def get_next_active(next_target, id, max, final) do
    cond do
      next_in_line(id, max) == final ->
        0

      next_target == final ->
        0

      next_in_line(id, max) != final || next_target != final ->
        case GenServer.call(node_name(next_in_line(next_target, max)), :is_active, :infinity) do
          Active -> next_in_line(next_target, max)
          Inactive -> get_next_active(next_target + 1, id, max, final)
        end
    end

    # case next_in_line(id, max) == final do
    #   true ->
    #     0

    #   false -> next_target + 1
    #     # case GenServer.call(node_name(next_in_line(next_target, max)), :is_active) do
    #     #   Active -> next_target + 1
    #     #   Inactive -> get_next_active(next_in_line(next_target, max), id, max, final)
    #     # end
    # end
  end

  def next_in_line(node, max) do
    case node + 1 > max do
      true -> 1
      false -> node + 1
    end
  end

  def handle_call(:is_active, _from, state) do
    {:reply, state.status, state}
  end

  def find_next_target(list, final_target) do
    # Enum.min_by list, fn i ->
    #   if i <= final_target do
    #     final_target - i
    #   end
    # end
    Enum.max(Enum.filter(list, fn x -> x <= final_target end))
  end

  def node_name(x) do
    a = x |> Integer.to_string() |> String.pad_leading(4, "0")

    ("Elixir.N" <> a)
    |> String.to_atom()
  end
end
