defmodule Orgchart.TreeBuilder do
  @moduledoc """
  Builds a hierarchical tree from a flat list of Person structs.
  """

  alias Orgchart.Person

  @spec build([Person.t()]) :: {:ok, Person.t()} | {:error, String.t()}
  def build(persons) do
    with :ok <- validate_persons(persons),
         index <- build_index(persons),
         {:ok, root} <- find_root(persons),
         {:ok, tree} <- build_tree(root, index) do
      {:ok, calculate_counts(tree)}
    end
  end

  defp validate_persons([]), do: {:error, "No persons provided"}

  defp validate_persons(persons) do
    with :ok <- check_for_duplicates(persons),
         :ok <- check_for_orphans(persons) do
      check_for_cycles(persons)
    end
  end

  defp check_for_duplicates(persons) do
    names = Enum.map(persons, & &1.name)
    duplicates = names -- Enum.uniq(names)

    if Enum.empty?(duplicates) do
      :ok
    else
      {:error, "Duplicate names found: #{Enum.join(Enum.uniq(duplicates), ", ")}"}
    end
  end

  defp check_for_orphans(persons) do
    names = MapSet.new(Enum.map(persons, & &1.name))

    orphans =
      persons
      |> Enum.filter(fn p -> p.lead != nil and not MapSet.member?(names, p.lead) end)
      |> Enum.map(fn p -> "#{p.name} (lead: #{p.lead})" end)

    if Enum.empty?(orphans) do
      :ok
    else
      {:error, "Orphan persons with missing leads: #{Enum.join(orphans, ", ")}"}
    end
  end

  defp check_for_cycles(persons) do
    index = Map.new(persons, &{&1.name, &1})

    cycles =
      Enum.filter(persons, fn person ->
        has_cycle?(person.name, index, MapSet.new())
      end)

    if Enum.empty?(cycles) do
      :ok
    else
      {:error,
       "Circular references detected involving: #{Enum.map_join(cycles, ", ", & &1.name)}"}
    end
  end

  defp has_cycle?(_name, index, _visited) when map_size(index) == 0, do: false

  defp has_cycle?(name, index, visited) do
    if MapSet.member?(visited, name) do
      true
    else
      case Map.get(index, name) do
        nil -> false
        person when person.lead == nil -> false
        person -> has_cycle?(person.lead, index, MapSet.put(visited, name))
      end
    end
  end

  defp build_index(persons) do
    Map.new(persons, &{&1.name, &1})
  end

  defp find_root(persons) do
    roots = Enum.filter(persons, &is_nil(&1.lead))

    case roots do
      [] ->
        {:error, "No root found (person without a lead)"}

      [root] ->
        {:ok, root}

      multiple ->
        {:error, "Multiple roots found: #{Enum.map_join(multiple, ", ", & &1.name)}"}
    end
  end

  defp build_tree(person, index) do
    children =
      index
      |> Map.values()
      |> Enum.filter(&(&1.lead == person.name))
      |> Enum.sort_by(& &1.name)
      |> Enum.map(fn child ->
        {:ok, child_tree} = build_tree(child, index)
        child_tree
      end)

    {:ok, %{person | children: children}}
  end

  defp calculate_counts(person) do
    children = Enum.map(person.children, &calculate_counts/1)
    direct_count = length(children)
    total_count = direct_count + Enum.sum(Enum.map(children, & &1.total_count))

    %{person | children: children, direct_count: direct_count, total_count: total_count}
  end
end
