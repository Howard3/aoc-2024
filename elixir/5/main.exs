defmodule PagesAndUpdates do
  defstruct page_order_rules: %{}, updates: %{}

  def new(blob) do
    [pages, updates] = String.split(blob, "\n\n", parts: 2)

    pages =
      parse_lines(pages, "|")
      |> get_page_priorities

    updates = updates |> parse_lines(",")

    %PagesAndUpdates{page_order_rules: pages, updates: updates}
  end

  defp parse_lines(updates_blob, sep) do
    updates_blob
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&parse_numbers(&1, sep))
  end

  defp parse_numbers(string, sep),
    do: string |> String.split(sep) |> Enum.map(&String.to_integer/1)

  defp get_page_priorities(rules, priorities \\ %{})

  defp get_page_priorities([[first, second] | remaining], priorities) do
    priorities = Map.put(priorities, first, [second | Map.get(priorities, first, [])])
    get_page_priorities(remaining, priorities)
  end

  defp get_page_priorities([], priorities), do: priorities

  def get_ordered_updates(data = %__MODULE__{}) do
    data.updates
    |> Enum.filter(&update_is_ordered?(&1, data.page_order_rules))
  end

  defp fix_order(update, order_rules) do
    Enum.sort(update, fn v1, v2 -> v1 in get_lower_priority_values(order_rules, v2) end)
  end

  def get_and_fix_unordered_updates(data = %__MODULE__{}) do
    data.updates
    |> Enum.filter(&(!update_is_ordered?(&1, data.page_order_rules)))
    |> Enum.map(&fix_order(&1, data.page_order_rules))
  end

  defp update_is_ordered?([], _order_rules), do: true

  defp update_is_ordered?([first | rest], order_rules) do
    if is_higher_value_than_rest?(order_rules, first, rest) do
      update_is_ordered?(rest, order_rules)
    else
      false
    end
  end

  defp is_higher_value_than_rest?(_order_rules, _value, []), do: true

  defp is_higher_value_than_rest?(order_rules, value, [next | rest]) when is_number(value) do
    cond do
      value in get_lower_priority_values(order_rules, next) -> false
      true -> is_higher_value_than_rest?(order_rules, value, rest)
    end
  end

  defp get_lower_priority_values(order_rules, value), do: Map.get(order_rules, value, [])
end

defmodule PrintQueue do
  def start() do
    pages_and_updates =
      "input.txt"
      |> File.read!()
      |> PagesAndUpdates.new()

    PagesAndUpdates.get_ordered_updates(pages_and_updates)
    |> add_middle_numbers()
    |> print(1)

    PagesAndUpdates.get_and_fix_unordered_updates(pages_and_updates)
    |> add_middle_numbers()
    |> print(2)
  end

  defp print(value, part), do: IO.puts("Part #{part}: #{value}")

  defp add_middle_numbers(_updates, acc \\ 0)
  defp add_middle_numbers([], acc) when is_number(acc), do: acc

  defp add_middle_numbers([this_update | remaining], acc) do
    add_middle_numbers(remaining, acc + get_middle_value(this_update))
  end

  defp get_middle_value(update), do: Enum.at(update, get_middle_index(update))
  defp get_middle_index(update) when is_list(update), do: floor(length(update) / 2)
end

PrintQueue.start()
