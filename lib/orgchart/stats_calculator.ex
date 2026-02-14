defmodule Orgchart.StatsCalculator do
  @moduledoc """
  Calculates statistics from the organization tree.
  """

  alias Orgchart.Person

  @type stats :: %{
          total_size: non_neg_integer(),
          by_role: %{String.t() => non_neg_integer()},
          by_team: %{String.t() => non_neg_integer()}
        }

  @spec calculate(Person.t()) :: stats()
  def calculate(root) do
    persons = flatten_tree(root)

    %{
      total_size: length(persons),
      by_role: count_by(persons, & &1.role),
      by_team: count_by(persons, & &1.team)
    }
  end

  defp flatten_tree(person) do
    [person | Enum.flat_map(person.children, &flatten_tree/1)]
  end

  defp count_by(persons, key_fn) do
    persons
    |> Enum.group_by(key_fn)
    |> Enum.map(fn {key, group} -> {key, length(group)} end)
    |> Enum.sort_by(fn {_key, count} -> -count end)
    |> Map.new()
  end
end
