defmodule TaskMasterWeb.Helpers.Sorting do
  @sort_criteria [
    %{label: "Title", field: :title, status: :inactive, type: :alpha},
    %{label: "Due Date", field: :due_date, status: :inactive, type: :numeric},
    %{label: "Duration", field: :duration, status: :inactive, type: :numeric},
    %{label: "Priority", field: :priority, status: :inactive, type: :alpha},
    %{label: "Indoor", field: :indoor, status: :inactive, type: :alpha}
  ]

  def get_default_sort_criteria() do
    @sort_criteria
  end

  def parse_sort_by(field) do
    @sort_criteria
    |> Enum.find(fn c -> Atom.to_string(c.field) == field end)
    |> Map.get(:field)
  end

  def parse_sort_order(status) do
    case status do
      "inactive" -> :inactive
      "asc" -> :asc
      "desc" -> :desc
      _ -> raise "Unknown sort order"
    end
  end

  def compute_sort_criteria(sort_by, sort_order) do
    @sort_criteria
    |> Enum.map(fn c ->
      if c.field == sort_by do
        %{c | status: sort_order}
      else
        c
      end
    end)
  end

  def compute_new_sort_criteria(field, old_status) do
    sort_by =
      @sort_criteria |> Enum.find(fn c -> Atom.to_string(c.field) == field end) |> Map.get(:field)

    sort_order =
      case old_status do
        "inactive" -> :asc
        "asc" -> :desc
        "desc" -> :inactive
      end

    new_criteria =
      @sort_criteria
      |> Enum.map(fn c ->
        if c.field == sort_by do
          %{c | status: sort_order}
        else
          c
        end
      end)

    {new_criteria, sort_by, sort_order}
  end
end
