defmodule TaskMasterWeb.Helpers.Sorting do
  @sort_criteria [
    %{label: "Title", field: :title, status: :inactive, type: :alpha},
    %{label: "Due Date", field: :due_date, status: :inactive, type: :numeric},
    %{label: "Duration", field: :duration, status: :inactive, type: :numeric},
    %{label: "Priority", field: :priority, status: :inactive, type: :alpha},
    %{label: "Indoor", field: :indoor, status: :inactive, type: :alpha}
  ]

  def get_default_sort_criteria, do: @sort_criteria

  def parse_sort_criteria(params) do
    Enum.reduce(@sort_criteria, [], fn criterion, acc ->
      case Map.get(params, Atom.to_string(criterion.field)) do
        "asc" -> [{criterion.field, :asc} | acc]
        "desc" -> [{criterion.field, :desc} | acc]
        _ -> acc
      end
    end)
    |> Enum.reverse()
  end

  def compute_new_sort_criteria(field, old_status, current_criteria) do
    new_status =
      case old_status do
        "inactive" -> :asc
        "asc" -> :desc
        "desc" -> :inactive
      end

    new_criteria =
      Enum.map(@sort_criteria, fn c ->
        if c.field == String.to_existing_atom(field) do
          %{c | status: new_status}
        else
          c
        end
      end)

    sort_criteria =
      case new_status do
        :inactive ->
          List.keydelete(current_criteria, String.to_existing_atom(field), 0)

        _ ->
          [
            {String.to_existing_atom(field), new_status}
            | List.keydelete(current_criteria, String.to_existing_atom(field), 0)
          ]
      end

    {new_criteria, sort_criteria}
  end
end
