defmodule TaskMasterWeb.Components.TaskComponents do
  use Phoenix.Component

  alias TaskMasterWeb.Helpers.Formatted

  attr(:participant, :string, required: true)

  def nick_name(assigns) do
    ~H"""
    <span class="px-2 py-1 text-sm font-semibold text-blue-800 bg-blue-100 rounded-full whitespace-nowrap">
      <%= Formatted.downcase(@participant) %>
    </span>
    """
  end
end
