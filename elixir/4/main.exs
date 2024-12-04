defmodule Grid do
  defstruct [:rows]

  def new(blob) do
    blob
    |> String.split("\n")
    |> Enum.map(&String.graphemes/1)
    |> then(&%Grid{rows: &1})
  end

  def row_count(grid = %Grid{}), do: length(grid.rows)
  def col_count(grid = %Grid{}), do: length(Enum.at(grid.rows, 0))

  defp get_all_search_patterns() do
    range = [-1, 0, 1]

    for x <- range, y <- range do
      [row: x, col: y]
    end
    |> List.delete(row: 0, col: 0)
  end

  defp get_diagonal_search_patterns() do
    get_all_search_patterns()
    |> Enum.filter(fn transform -> transform[:row] != 0 && transform[:col] != 0 end)
  end

  defp get_value(grid, row, col), do: Enum.at(grid.rows, row) |> Enum.at(col)

  def all_matches_from_position(grid, pos = [row: _, col: _], pattern) do
    get_all_search_patterns()
    |> Stream.map(&search_pattern(grid, pos, pattern, &1))
    |> Stream.filter(fn x -> elem(x, 0) == :found end)
    |> Enum.count()
  end

  def cross_match_coordinates_from_position(grid, pos = [row: _, col: _], pattern, coord_index) do
    get_diagonal_search_patterns()
    |> Stream.map(&search_pattern(grid, pos, pattern, &1))
    |> Enum.filter(fn x -> elem(x, 0) == :found end)
    |> Enum.map(fn result -> Enum.at(elem(result, 1), coord_index) end)
  end

  defp search_pattern(grid = %Grid{}, pos = [row: row, col: col], pattern, transform, path \\ []) do
    {next, remaining} = String.split_at(pattern, 1)
    current = get_value(grid, row, col)
    next_row = row + transform[:row]
    next_col = col + transform[:col]
    path = [pos | path]

    cond do
      current != next ->
        {:notfound}

      String.length(remaining) == 0 ->
        {:found, path}

      next_col < 0 || next_row < 0 ->
        {:notfound}

      true ->
        search_pattern(grid, [row: next_row, col: next_col], remaining, transform, path)
    end
  end
end

defmodule CeresSearch do
  @pattern "XMAS"
  @pattern2 "MAS"
  def start() do
    grid =
      "input.txt"
      |> File.read!()
      |> Grid.new()

    grid
    |> get_col_row_pairs()
    |> Enum.map(&Grid.all_matches_from_position(grid, &1, @pattern))
    |> Enum.sum()
    |> print_part(1)

    grid
    |> get_col_row_pairs()
    |> Stream.map(&Grid.cross_match_coordinates_from_position(grid, &1, @pattern2, 1))
    |> Stream.filter(fn match -> length(match) > 0 end)
    |> Stream.concat()
    |> Enum.frequencies()
    |> Enum.count(fn {_coords, count} -> count > 1 end)
    |> print_part(2)
  end

  defp get_col_row_pairs(grid = %Grid{}) do
    for row <- 0..(Grid.row_count(grid) - 1), col <- 0..(Grid.col_count(grid) - 1) do
      [row: row, col: col]
    end
  end

  defp print_part(val, num), do: IO.puts("Part #{num}: #{val}")
end

CeresSearch.start()
