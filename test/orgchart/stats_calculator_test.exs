defmodule Orgchart.StatsCalculatorTest do
  use ExUnit.Case, async: true

  alias Orgchart.Person
  alias Orgchart.StatsCalculator
  alias Orgchart.TreeBuilder

  defp create_person(attrs) do
    Person.new(Map.merge(%{lead: nil}, attrs))
  end

  defp build_tree(persons) do
    {:ok, root} = TreeBuilder.build(persons)
    root
  end

  describe "calculate/1" do
    test "calculates total size" do
      root =
        build_tree([
          create_person(%{name: "CEO Boss", role: "CEO", team: "Executive"}),
          create_person(%{name: "VP One", role: "VP", team: "Engineering", lead: "CEO Boss"}),
          create_person(%{name: "Eng One", role: "Engineer", team: "Engineering", lead: "VP One"})
        ])

      stats = StatsCalculator.calculate(root)

      assert stats.total_size == 3
    end

    test "counts by role" do
      root =
        build_tree([
          create_person(%{name: "CEO Boss", role: "CEO", team: "Executive"}),
          create_person(%{name: "Eng One", role: "Engineer", team: "Engineering", lead: "CEO Boss"}),
          create_person(%{name: "Eng Two", role: "Engineer", team: "Engineering", lead: "CEO Boss"}),
          create_person(%{name: "Designer One", role: "Designer", team: "Product", lead: "CEO Boss"})
        ])

      stats = StatsCalculator.calculate(root)

      assert stats.by_role["Engineer"] == 2
      assert stats.by_role["CEO"] == 1
      assert stats.by_role["Designer"] == 1
    end

    test "counts by team" do
      root =
        build_tree([
          create_person(%{name: "CEO Boss", role: "CEO", team: "Executive"}),
          create_person(%{name: "Eng One", role: "Engineer", team: "Engineering", lead: "CEO Boss"}),
          create_person(%{name: "Eng Two", role: "Engineer", team: "Engineering", lead: "CEO Boss"}),
          create_person(%{name: "Sales One", role: "Sales Rep", team: "Sales", lead: "CEO Boss"})
        ])

      stats = StatsCalculator.calculate(root)

      assert stats.by_team["Engineering"] == 2
      assert stats.by_team["Executive"] == 1
      assert stats.by_team["Sales"] == 1
    end

    test "handles single person organization" do
      root =
        build_tree([
          create_person(%{name: "Solo Founder", role: "CEO", team: "Executive"})
        ])

      stats = StatsCalculator.calculate(root)

      assert stats.total_size == 1
      assert stats.by_role["CEO"] == 1
      assert stats.by_team["Executive"] == 1
    end

    test "handles deeply nested structure" do
      root =
        build_tree([
          create_person(%{name: "L1 Person", role: "CEO", team: "Executive"}),
          create_person(%{name: "L2 Person", role: "VP", team: "Engineering", lead: "L1 Person"}),
          create_person(%{name: "L3 Person", role: "Manager", team: "Engineering", lead: "L2 Person"}),
          create_person(%{name: "L4 Person", role: "Engineer", team: "Engineering", lead: "L3 Person"})
        ])

      stats = StatsCalculator.calculate(root)

      assert stats.total_size == 4
      assert stats.by_team["Engineering"] == 3
      assert stats.by_team["Executive"] == 1
    end
  end
end
