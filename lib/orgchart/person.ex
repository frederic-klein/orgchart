defmodule Orgchart.Person do
  @moduledoc """
  Represents a person in the organization chart.
  """

  @enforce_keys [:name, :role, :team]
  defstruct [
    :name,
    :role,
    :team,
    :lead,
    children: [],
    direct_count: 0,
    total_count: 0
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          role: String.t(),
          team: String.t(),
          lead: String.t() | nil,
          children: [t()],
          direct_count: non_neg_integer(),
          total_count: non_neg_integer()
        }

  @spec new(map()) :: t()
  def new(attrs) do
    lead =
      case Map.get(attrs, :lead, "") do
        nil -> nil
        "" -> nil
        lead_name -> String.trim(lead_name)
      end

    %__MODULE__{
      name: String.trim(Map.fetch!(attrs, :name)),
      role: String.trim(Map.fetch!(attrs, :role)),
      team: String.trim(Map.fetch!(attrs, :team)),
      lead: lead
    }
  end
end
