defmodule OrgchartWeb.OrgchartLive do
  use OrgchartWeb, :live_view

  alias Orgchart.CsvParser
  alias Orgchart.StatsCalculator
  alias Orgchart.TreeBuilder

  @default_csv_path "priv/data/qvision.csv"

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> allow_upload(:csv_file, accept: ~w(.csv), max_entries: 1)
      |> load_default_chart()

    {:ok, socket}
  end

  defp load_default_chart(socket) do
    case load_org_chart_from_file(@default_csv_path) do
      {:ok, root, stats} ->
        assign(socket, root: root, stats: stats, error: nil)

      {:error, reason} ->
        assign(socket, root: nil, stats: nil, error: reason)
    end
  end

  defp load_org_chart_from_file(path) do
    with {:ok, persons} <- CsvParser.parse_file(path),
         {:ok, root} <- TreeBuilder.build(persons) do
      stats = StatsCalculator.calculate(root)
      {:ok, root, stats}
    end
  end

  defp load_org_chart_from_content(content) do
    with {:ok, persons} <- CsvParser.parse_content(content),
         {:ok, root} <- TreeBuilder.build(persons) do
      stats = StatsCalculator.calculate(root)
      {:ok, root, stats}
    end
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("upload", _params, socket) do
    case consume_uploaded_entries(socket, :csv_file, fn %{path: path}, _entry ->
           {:ok, File.read!(path)}
         end) do
      [content] ->
        socket =
          case load_org_chart_from_content(content) do
            {:ok, root, stats} ->
              assign(socket, root: root, stats: stats, error: nil)

            {:error, reason} ->
              assign(socket, error: reason)
          end

        {:noreply, socket}

      [] ->
        {:noreply, assign(socket, error: "No file selected")}
    end
  end

  @impl true
  def handle_event("load-sample", _params, socket) do
    {:noreply, load_default_chart(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100 py-8">
      <div class="mx-auto px-4">
        <h1 class="text-2xl font-semibold text-gray-800 mb-6 text-center">Organization Chart</h1>

        <.upload_form uploads={@uploads} />

        <%= if @error do %>
          <.error_message message={@error} />
        <% end %>

        <%= if @root do %>
          <.stats_legend stats={@stats} />
          <div class="bg-white rounded-xl shadow-sm p-8 overflow-x-auto">
            <div class="org-chart">
              <.tree_node person={@root} is_root={true} />
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp upload_form(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-md p-6 mb-6">
      <form id="upload-form" phx-submit="upload" phx-change="validate" class="flex items-center gap-4 flex-wrap">
        <div class="flex-1 min-w-[200px]">
          <label class="block text-sm font-medium text-gray-700 mb-2">Upload CSV File</label>
          <.live_file_input upload={@uploads.csv_file} class="block w-full text-sm text-gray-500
            file:mr-4 file:py-2 file:px-4
            file:rounded-md file:border-0
            file:text-sm file:font-semibold
            file:bg-blue-50 file:text-blue-700
            hover:file:bg-blue-100
            cursor-pointer" />
        </div>

        <div class="flex gap-2 pt-6">
          <button
            type="submit"
            class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            disabled={@uploads.csv_file.entries == []}
          >
            Load Chart
          </button>
          <button
            type="button"
            phx-click="load-sample"
            class="px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300 transition-colors"
          >
            Load Sample
          </button>
        </div>
      </form>

      <%= for entry <- @uploads.csv_file.entries do %>
        <div class="mt-2 text-sm text-gray-600">
          Selected: {entry.client_name}
          <%= for err <- upload_errors(@uploads.csv_file, entry) do %>
            <span class="text-red-500 ml-2">{error_to_string(err)}</span>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp error_to_string(:too_large), do: "File is too large"
  defp error_to_string(:not_accepted), do: "Invalid file type (must be .csv)"
  defp error_to_string(:too_many_files), do: "Too many files"
  defp error_to_string(err), do: inspect(err)

  defp error_message(assigns) do
    ~H"""
    <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6" role="alert">
      <strong class="font-bold">Error: </strong>
      <span class="block sm:inline">{@message}</span>
    </div>
    """
  end

  defp stats_legend(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-md p-6 mb-6">
      <h2 class="text-xl font-semibold text-gray-800 mb-4">Organization Statistics</h2>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="bg-blue-50 rounded-lg p-4">
          <h3 class="text-sm font-medium text-blue-800 uppercase tracking-wide">Total Size</h3>
          <p class="text-3xl font-bold text-blue-900 mt-2">{@stats.total_size}</p>
        </div>

        <div class="bg-green-50 rounded-lg p-4">
          <h3 class="text-sm font-medium text-green-800 uppercase tracking-wide mb-2">By Role</h3>
          <ul class="space-y-1">
            <%= for {role, count} <- @stats.by_role do %>
              <li class="flex justify-between text-sm">
                <span class="text-gray-700">{role}</span>
                <span class="font-medium text-green-700">{count}</span>
              </li>
            <% end %>
          </ul>
        </div>

        <div class="bg-purple-50 rounded-lg p-4">
          <h3 class="text-sm font-medium text-purple-800 uppercase tracking-wide mb-2">By Team</h3>
          <ul class="space-y-1">
            <%= for {team, count} <- @stats.by_team do %>
              <li class="flex justify-between text-sm">
                <span class="text-gray-700">{team}</span>
                <span class="font-medium text-purple-700">{count}</span>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  defp tree_node(assigns) do
    # Group by role, then by team within each role
    children_by_role_and_team =
      assigns.person.children
      |> Enum.group_by(& &1.role)
      |> Enum.map(fn {role, children} ->
        teams = Enum.group_by(children, & &1.team)
        {role, length(children), teams}
      end)
      |> Enum.sort_by(fn {role, _, _} -> role end)

    assigns =
      assigns
      |> assign(:children_by_role_and_team, children_by_role_and_team)
      |> assign_new(:is_root, fn -> false end)
      |> assign(:initials, get_initials(assigns.person.name))
      |> assign(:team_class, team_to_class(assigns.person.team))

    ~H"""
    <div class="tree-node">
      <.person_card person={@person} initials={@initials} team_class={@team_class} />

      <%= if @children_by_role_and_team != [] do %>
        <div class="role-columns">
          <%= for {role, role_count, teams_map} <- @children_by_role_and_team do %>
            <div class="role-column">
              <div class="role-header">
                {role} <span>({role_count})</span>
              </div>
              <%= for {team, children} <- teams_map do %>
                <div class="team-subgroup">
                  <div class="team-label">{team}</div>
                  <div class="team-members">
                    <%= for child <- children do %>
                      <.tree_node person={child} />
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp person_card(assigns) do
    ~H"""
    <div class={"person-card #{@team_class}"}>
      <div class="person-avatar">{@initials}</div>
      <div class="person-info">
        <div class="person-name">{@person.name}</div>
        <div class="person-role">{@person.role}</div>
        <div class="person-team">{@person.team}</div>
        <%= if @person.total_count > 0 do %>
          <div class="person-counts">
            {@person.total_count} total / {@person.direct_count} direct
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp get_initials(name) do
    name
    |> String.split()
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end

  defp team_to_class(team) do
    team_lower = String.downcase(team)

    cond do
      String.contains?(team_lower, "executive") -> "team-executive"
      String.contains?(team_lower, "engineering") -> "team-engineering"
      String.contains?(team_lower, "product") -> "team-product"
      String.contains?(team_lower, "design") -> "team-design"
      String.contains?(team_lower, "sales") -> "team-sales"
      String.contains?(team_lower, "marketing") -> "team-marketing"
      String.contains?(team_lower, "hr") or String.contains?(team_lower, "human") -> "team-hr"
      String.contains?(team_lower, "finance") -> "team-finance"
      String.contains?(team_lower, "operation") -> "team-operations"
      true -> "team-default"
    end
  end
end
