defmodule Orgchart.TreeBuilderTest do
  use ExUnit.Case, async: true

  alias Orgchart.Person
  alias Orgchart.TreeBuilder

  defp create_person(attrs) do
    Person.new(Map.merge(%{role: "Employee", team: "Team"}, attrs))
  end

  describe "build/1" do
    test "builds tree from flat list with single root" do
      persons = [
        create_person(%{name: "Sarah Johnson", lead: nil}),
        create_person(%{name: "Michael Chen", lead: "Sarah Johnson"}),
        create_person(%{name: "Emily Davis", lead: "Sarah Johnson"})
      ]

      assert {:ok, root} = TreeBuilder.build(persons)

      assert root.name == "Sarah Johnson"
      assert length(root.children) == 2
      assert root.direct_count == 2
      assert root.total_count == 2
    end

    test "builds nested tree structure" do
      persons = [
        create_person(%{name: "CEO Boss", lead: nil}),
        create_person(%{name: "VP One", lead: "CEO Boss"}),
        create_person(%{name: "Manager One", lead: "VP One"}),
        create_person(%{name: "Engineer One", lead: "Manager One"})
      ]

      assert {:ok, root} = TreeBuilder.build(persons)

      assert root.name == "CEO Boss"
      assert root.direct_count == 1
      assert root.total_count == 3

      vp = hd(root.children)
      assert vp.name == "VP One"
      assert vp.direct_count == 1
      assert vp.total_count == 2

      manager = hd(vp.children)
      assert manager.name == "Manager One"
      assert manager.direct_count == 1
      assert manager.total_count == 1

      engineer = hd(manager.children)
      assert engineer.name == "Engineer One"
      assert engineer.direct_count == 0
      assert engineer.total_count == 0
    end

    test "calculates counts correctly for wide tree" do
      persons = [
        create_person(%{name: "CEO Boss", lead: nil}),
        create_person(%{name: "VP A", lead: "CEO Boss"}),
        create_person(%{name: "VP B", lead: "CEO Boss"}),
        create_person(%{name: "VP C", lead: "CEO Boss"}),
        create_person(%{name: "Eng One", lead: "VP A"}),
        create_person(%{name: "Eng Two", lead: "VP A"})
      ]

      assert {:ok, root} = TreeBuilder.build(persons)

      assert root.direct_count == 3
      assert root.total_count == 5

      vp_a = Enum.find(root.children, &(&1.name == "VP A"))
      assert vp_a.direct_count == 2
      assert vp_a.total_count == 2
    end

    test "returns error for empty list" do
      assert {:error, "No persons provided"} = TreeBuilder.build([])
    end

    test "returns error when no root found" do
      persons = [
        create_person(%{name: "A Person", lead: "B Person"}),
        create_person(%{name: "B Person", lead: "C Person"}),
        create_person(%{name: "C Person", lead: "A Person"})
      ]

      assert {:error, message} = TreeBuilder.build(persons)
      assert message =~ "Circular references"
    end

    test "returns error for multiple roots" do
      persons = [
        create_person(%{name: "CEO One", lead: nil}),
        create_person(%{name: "CEO Two", lead: nil})
      ]

      assert {:error, message} = TreeBuilder.build(persons)
      assert message =~ "Multiple roots found"
    end

    test "returns error for duplicate names" do
      persons = [
        create_person(%{name: "John Doe", lead: nil}),
        create_person(%{name: "John Doe", lead: nil})
      ]

      assert {:error, message} = TreeBuilder.build(persons)
      assert message =~ "Duplicate names"
    end

    test "returns error for orphan with missing lead" do
      persons = [
        create_person(%{name: "CEO Boss", lead: nil}),
        create_person(%{name: "Orphan Person", lead: "Non Existent"})
      ]

      assert {:error, message} = TreeBuilder.build(persons)
      assert message =~ "Orphan persons"
      assert message =~ "Non Existent"
    end

    test "returns error for circular reference" do
      persons = [
        create_person(%{name: "A Person", lead: "B Person"}),
        create_person(%{name: "B Person", lead: "C Person"}),
        create_person(%{name: "C Person", lead: "A Person"})
      ]

      assert {:error, message} = TreeBuilder.build(persons)
      assert message =~ "Circular references"
    end

    test "sorts children alphabetically by name" do
      persons = [
        create_person(%{name: "CEO Boss", lead: nil}),
        create_person(%{name: "Zack Zebra", lead: "CEO Boss"}),
        create_person(%{name: "Alice Apple", lead: "CEO Boss"}),
        create_person(%{name: "Mike Miller", lead: "CEO Boss"})
      ]

      assert {:ok, root} = TreeBuilder.build(persons)

      child_names = Enum.map(root.children, & &1.name)
      assert child_names == ["Alice Apple", "Mike Miller", "Zack Zebra"]
    end
  end
end
