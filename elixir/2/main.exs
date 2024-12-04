defmodule RedNosedReports do
  @min_movement 1
  @max_movement 3

  def start() do
    report =
      "inputs.txt"
      |> File.read!()
      |> String.split("\n")
      |> Enum.filter(fn x -> String.length(x) > 0 end)
      |> Enum.map(&parse_report/1)

    report
    |> Enum.filter(&is_linear_safe/1)
    |> Enum.count()
    |> print_part(1)

    report
    |> Enum.filter(&is_linear_safe_with_dampener/1)
    |> Enum.count()
    |> print_part(2)
  end

  defp print_part(res, partnum), do: IO.puts("Part #{partnum}: #{res}")

  defp parse_report(report) do
    report
    |> String.split(" ")
    |> Enum.map(&String.to_integer/1)
  end

  defp is_linear_safe_with_dampener(report) do
    report
    |> is_linear_safe
    |> run_dampened_reports(report)
  end

  defp run_dampened_reports(true, _report), do: true

  defp run_dampened_reports(false, report) do
    report
    |> gen_report_variations
    |> Enum.filter(&is_linear_safe/1)
    |> Enum.count()
    |> then(fn x -> x > 0 end)
  end

  defp gen_report_variations(report) do
    0..(length(report) - 1)
    |> Enum.reduce([], fn i, acc ->
      new_report =
        report
        |> List.pop_at(i)
        |> elem(1)

      [new_report | acc]
    end)
  end

  defp is_linear_safe(report) do
    report
    |> reverse_if_descending
    |> Enum.reduce(nil, &is_safe_increase/2)
    |> elem(0)
  end

  defp reverse_if_descending([x, y | _] = report) when x > y, do: Enum.reverse(report)
  defp reverse_if_descending(report), do: report

  defp is_safe_increase(x, nil), do: {true, x}
  defp is_safe_increase(_, {false, _}), do: {false, nil}

  defp is_safe_increase(value, {true, previous_value}) when is_number(previous_value) do
    min = previous_value + @min_movement
    max = previous_value + @max_movement
    {value >= min && value <= max, value}
  end
end

RedNosedReports.start()
