defmodule Orgchart.CsvParserTest do
  use ExUnit.Case, async: true

  alias Orgchart.CsvParser
  alias Orgchart.Person

  describe "detect_delimiter/1" do
    test "detects semicolon delimiter" do
      csv = "name;role;team;lead\nSarah Johnson;CEO;Executive;"
      assert CsvParser.detect_delimiter(csv) == ";"
    end

    test "detects comma delimiter" do
      csv = "name,role,team,lead\nSarah Johnson,CEO,Executive,"
      assert CsvParser.detect_delimiter(csv) == ","
    end

    test "detects semicolon when both present but semicolons dominate" do
      csv = "name;role;team;lead\nJohn, Jr.;Developer;Engineering;"
      assert CsvParser.detect_delimiter(csv) == ";"
    end

    test "detects comma when both present but commas dominate" do
      csv = "name,role,team,lead\nJohn; Jr.,Developer,Engineering,"
      assert CsvParser.detect_delimiter(csv) == ","
    end

    test "defaults to comma when no clear delimiter" do
      csv = "just some text"
      assert CsvParser.detect_delimiter(csv) == ","
    end
  end

  describe "parse_content/1" do
    test "parses semicolon-separated CSV" do
      csv = """
      name;role;team;lead
      Sarah Johnson;CEO;Executive;
      Michael Chen;VP Engineering;Engineering;Sarah Johnson
      """

      assert {:ok, persons} = CsvParser.parse_content(csv)
      assert length(persons) == 2

      [sarah, michael] = persons

      assert %Person{
               name: "Sarah Johnson",
               role: "CEO",
               team: "Executive",
               lead: nil
             } = sarah

      assert %Person{
               name: "Michael Chen",
               role: "VP Engineering",
               team: "Engineering",
               lead: "Sarah Johnson"
             } = michael
    end

    test "parses comma-separated CSV" do
      csv = """
      name,role,team,lead
      Sarah Johnson,CEO,Executive,
      Michael Chen,VP Engineering,Engineering,Sarah Johnson
      """

      assert {:ok, persons} = CsvParser.parse_content(csv)
      assert length(persons) == 2

      [sarah, michael] = persons
      assert sarah.name == "Sarah Johnson"
      assert michael.lead == "Sarah Johnson"
    end

    test "trims whitespace from fields" do
      csv = """
      name;role;team;lead
       John Doe ; Developer ; Engineering ; Jane Smith
      """

      assert {:ok, [person]} = CsvParser.parse_content(csv)
      assert person.name == "John Doe"
      assert person.role == "Developer"
      assert person.team == "Engineering"
      assert person.lead == "Jane Smith"
    end

    test "handles empty lead field" do
      csv = """
      name;role;team;lead
      Sarah Johnson;CEO;Executive;
      """

      assert {:ok, [person]} = CsvParser.parse_content(csv)
      assert person.lead == nil
    end

    test "handles quoted fields with delimiter inside" do
      csv = """
      name;role;team;lead
      "John; Jr.";Developer;Engineering;
      """

      assert {:ok, [person]} = CsvParser.parse_content(csv)
      assert person.name == "John; Jr."
    end

    test "returns error for invalid row" do
      csv = """
      name;role;team;lead
      Sarah Johnson;CEO
      """

      assert {:error, message} = CsvParser.parse_content(csv)
      assert message =~ "Invalid CSV at line 2"
      assert message =~ "expected 4 columns"
    end
  end

  describe "parse_file/1" do
    test "returns error for non-existent file" do
      assert {:error, message} = CsvParser.parse_file("/non/existent/file.csv")
      assert message =~ "Failed to read file"
    end

    test "parses existing CSV file" do
      assert {:ok, persons} = CsvParser.parse_file("priv/data/employees.csv")
      assert persons != []

      ceo = Enum.find(persons, &(&1.role == "CEO"))
      assert ceo.lead == nil
    end
  end
end
