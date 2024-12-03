defmodule HistorianHysteria do
  def start do
    sorted_lists =
      File.read!("lists.txt")
      |> String.split("\n")
      |> Enum.filter(&remove_empty/1)
      |> Enum.map(&extract_values/1)
      |> sorted_left_right_lists

    sorted_lists
    |> calculate_left_right_diff
    |> print_part_1

    sorted_lists
    |> calculate_similarity_score
    |> print_part_2
  end

  defp to_int(x), do: String.to_integer(x)
  defp remove_empty(x), do: String.length(x) > 0
  defp print_part_1(x), do: IO.puts("Part 1 result: #{x}")
  defp print_part_2(x), do: IO.puts("Part 2 result: #{x}")

  defp extract_values(x) do
    pattern = ~r/(?<left>\d+)\s+(?<right>\d+)/

    Regex.scan(pattern, x)
    |> Enum.map(fn [_, left, right] -> [to_int(left), to_int(right)] end)
  end

  defp sorted_left_right_lists(x) do
    [left, right] =
      x
      |> Enum.reduce([[], []], fn [[new_left, new_right]], [acc_left, acc_right] ->
        [[new_left | acc_left], [new_right | acc_right]]
      end)

    [Enum.sort(left), Enum.sort(right)]
  end

  defp calculate_left_right_diff(lists) do
    lists
    |> Enum.zip_reduce(0, fn [left, right], acc -> acc + abs(left - right) end)
  end

  defp calculate_similarity_score([left, right]) do
    left
    |> Enum.reduce(0, fn left_value, acc ->
      acc + left_value * Enum.count(right, fn right_value -> left_value == right_value end)
    end)
  end
end

HistorianHysteria.start()
