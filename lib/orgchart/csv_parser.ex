defmodule Orgchart.CsvParser do
  @moduledoc """
  Parses CSV files into Person structs with auto-detection of delimiter.
  """

  alias Orgchart.Person

  NimbleCSV.define(CommaCSV, separator: ",", escape: "\"")
  NimbleCSV.define(SemicolonCSV, separator: ";", escape: "\"")

  @spec parse_file(String.t()) :: {:ok, [Person.t()]} | {:error, String.t()}
  def parse_file(path) do
    case File.read(path) do
      {:ok, content} ->
        parse_content(content)

      {:error, reason} ->
        {:error, "Failed to read file: #{inspect(reason)}"}
    end
  end

  @spec detect_delimiter(String.t()) :: String.t()
  def detect_delimiter(content) do
    first_line = content |> String.split("\n", parts: 2) |> hd()

    semicolons = count_unquoted(first_line, ";")
    commas = count_unquoted(first_line, ",")

    if semicolons > commas, do: ";", else: ","
  end

  defp count_unquoted(line, char) do
    line
    |> String.replace(~r/"[^"]*"/, "")
    |> String.graphemes()
    |> Enum.count(&(&1 == char))
  end

  @spec parse_content(String.t()) :: {:ok, [Person.t()]} | {:error, String.t()}
  def parse_content(content) do
    delimiter = detect_delimiter(content)
    parse_with_delimiter(content, delimiter)
  end

  defp parse_with_delimiter(content, ";") do
    do_parse(content, &SemicolonCSV.parse_string/2)
  end

  defp parse_with_delimiter(content, ",") do
    do_parse(content, &CommaCSV.parse_string/2)
  end

  defp do_parse(content, parser_fn) do
    rows = parser_fn.(content, skip_headers: true)

    rows
    |> Enum.with_index(2)
    |> Enum.reduce_while({:ok, []}, fn {row, line_num}, {:ok, acc} ->
      case row_to_person(row, line_num) do
        {:ok, person} -> {:cont, {:ok, [person | acc]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
    |> case do
      {:ok, persons} -> {:ok, Enum.reverse(persons)}
      {:error, _} = err -> err
    end
  rescue
    e in NimbleCSV.ParseError ->
      {:error, "CSV parse error: #{Exception.message(e)}"}
  end

  defp row_to_person([name, role, team, lead], _line_num) do
    {:ok, Person.new(%{name: name, role: role, team: team, lead: normalize_lead(lead)})}
  end

  defp row_to_person(row, line_num) do
    {:error,
     "Invalid CSV at line #{line_num}: expected 4 columns (name, role, team, lead), got #{length(row)}"}
  end

  defp normalize_lead(nil), do: nil

  defp normalize_lead(lead) when is_binary(lead) do
    case String.trim(lead) do
      "" -> nil
      trimmed -> trimmed
    end
  end
end
