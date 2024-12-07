defmodule GuardSimulator do
  defstruct [:map, guard_pos: {0, 0}, guard_dir: :unknown, visited: []]

  def new(blob) do
    map =
      blob
      |> String.split("\n")
      |> Enum.map(&process_map_line/1)

    {guard_position = {guard_x, guard_y}, guard_dir} = guard_orientation = get_guard_orientation(map)

    map = map |> List.update_at(guard_y, fn row -> List.update_at(row, guard_x, fn _ -> {:space} end) end)

    %GuardSimulator{map: map, guard_pos: guard_position, guard_dir: guard_dir, visited: [guard_orientation]}
  end

  def run_guard_simulation(data = %__MODULE__{}) do
    case move_guard(data) do
      {:off_map} -> data
      {:infinite_loop} -> :infinite_loop
      {:rotate, new_rotation} -> %__MODULE__{data | guard_dir: new_rotation} |> record_visited |> run_guard_simulation()
      {:move, new_pos} -> data |> update_pos(new_pos) |> record_visited |> run_guard_simulation()
    end
  end

  defp update_pos(data = %__MODULE__{}, pos = {_, _}),
    do: %__MODULE__{data | guard_pos: pos}

  defp record_visited(data = %__MODULE__{guard_pos: guard_pos, guard_dir: guard_dir, visited: visited}) do
    %__MODULE__{data | visited: [{guard_pos, guard_dir} | visited]}
  end

  defp move_guard(data = %__MODULE__{guard_pos: {x, y}, guard_dir: :up}), do: confirm_or_rotate(data, {x, y - 1})
  defp move_guard(data = %__MODULE__{guard_pos: {x, y}, guard_dir: :down}), do: confirm_or_rotate(data, {x, y + 1})
  defp move_guard(data = %__MODULE__{guard_pos: {x, y}, guard_dir: :left}), do: confirm_or_rotate(data, {x - 1, y})
  defp move_guard(data = %__MODULE__{guard_pos: {x, y}, guard_dir: :right}), do: confirm_or_rotate(data, {x + 1, y})

  defp confirm_or_rotate(data = %__MODULE__{visited: visited, guard_dir: guard_dir}, new_coords = {_, _}) do
    cond do
      !cell_exists?(data, new_coords) ->
        {:off_map}

      Enum.member?(visited, {new_coords, guard_dir}) ->
        {:infinite_loop}

      true ->
        case get_cell(data, new_coords) do
          {:space} -> {:move, new_coords}
          {:obstacle} -> {:rotate, new_rotation(data.guard_dir)}
        end
    end
  end

  def add_obstacle(data = %__MODULE__{map: map}, {x, y}) do
    map
    |> List.update_at(y, &List.update_at(&1, x, fn _ -> {:obstacle} end))
    |> then(&%__MODULE__{data | map: &1})
  end

  defp new_rotation(:up), do: :right
  defp new_rotation(:right), do: :down
  defp new_rotation(:down), do: :left
  defp new_rotation(:left), do: :up

  defp cell_exists?(data = %__MODULE__{}, {x, y}) do
    row = Enum.at(data.map, y)
    row != nil && Enum.at(row, x) != nil
  end

  defp get_cell(data = %__MODULE__{}, {x, y}), do: data.map |> Enum.at(y) |> Enum.at(x)

  defp get_guard_orientation([row | remaining_rows], y \\ 0) when is_list(row) do
    case find_guard_in_row(row) do
      {:found, x, dir} -> {{x, y}, dir}
      {:not_found} -> get_guard_orientation(remaining_rows, y + 1)
    end
  end

  defp find_guard_in_row(_cells, position \\ 0)
  defp find_guard_in_row([], _pos), do: {:not_found}
  defp find_guard_in_row([{:guard, direction} | _remaining_cells], position), do: {:found, position, direction}
  defp find_guard_in_row([_ | remaining_cells], position), do: find_guard_in_row(remaining_cells, position + 1)

  defp process_map_line(line) do
    line
    |> String.graphemes()
    |> Enum.map(&string_to_type/1)
  end

  defp string_to_type("."), do: {:space}
  defp string_to_type("#"), do: {:obstacle}
  defp string_to_type("^"), do: {:guard, :up}
end

defmodule GuardGallivant do
  def start(file \\ "input.txt") do
    guard_initial_state =
      file
      |> File.read!()
      |> GuardSimulator.new()

    guard_simulated = GuardSimulator.run_guard_simulation(guard_initial_state)

    guard_simulated.visited
    |> Enum.filter(fn {pos, _} -> pos != guard_initial_state.guard_pos end)
    |> Enum.map(fn {pos, _dir} -> pos end)
    |> Enum.uniq()
    |> Enum.map(&Task.async(fn -> simulated_obstacle_results_in_infinite_loop?(guard_initial_state, &1) end))
    |> Enum.map(&Task.await/1)
    |> Enum.filter(fn {_, is_infinite_loop?} -> is_infinite_loop? end)
    |> length()
    |> print(2)

    guard_simulated.visited
    |> Enum.uniq_by(fn {pos, _dir} -> pos end)
    |> length()
    |> print(1)

    dbg(guard_initial_state.guard_pos)
  end

  defp print(v, step), do: IO.puts("Step #{step}: #{v}")

  defp simulated_obstacle_results_in_infinite_loop?(guard_simulator, obstacle_position = {x, y}) do
    res =
      guard_simulator
      |> GuardSimulator.add_obstacle(obstacle_position)
      |> GuardSimulator.run_guard_simulation()

    if res == :infinite_loop do
      IO.puts("Infinite loop found @ obstacle_position #{x},#{y}")
    end

    {obstacle_position, res == :infinite_loop}
  end
end

GuardGallivant.start()
