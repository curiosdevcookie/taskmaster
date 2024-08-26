defmodule TaskMasterWeb.Components.TaskComponents do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  alias TaskMasterWeb.Helpers.Formatted
  import TaskMasterWeb.Gettext
  import TaskMasterWeb.CoreComponents

  attr(:participant, :string, required: true)

  def nick_name(assigns) do
    ~H"""
    <span class="px-2 py-1 text-sm font-semibold text-blue-800 bg-blue-100 rounded-full whitespace-nowrap">
      <%= Formatted.capitalize(@participant) %>
    </span>
    """
  end

  attr(:parent_tasks, :list, required: false)
  attr(:subtasks, :list, required: false)
  attr(:current_user, :any, required: false)
  attr(:navigate_fn, :any, required: true)
  attr(:patch_fn, :any, required: true)

  def task_list(assigns) do
    ~H"""
    <ul class="space-y-2">
      <%= for parent_task <- @parent_tasks do %>
        <.task_list_items
          parent_task={parent_task}
          subtasks={@subtasks}
          current_user={@current_user}
          navigate_fn={@navigate_fn}
          patch_fn={@patch_fn}
        />
      <% end %>
    </ul>
    """
  end

  def subtask_list(assigns) do
    ~H"""
    <ul
      id={"dropdown_id_#{@parent_task.id}"}
      class="hidden space-y-2 mt-4"
      phx-click-away={
        JS.hide(
          to: "#dropdown_id_#{@parent_task.id}",
          transition: {"ease-out duration-75", "opacity-100 scale-100", "opacity-0 scale-95"}
        )
        |> JS.toggle_class("rotate-90", to: "#chevron_id_#{@parent_task.id}")
      }
    >
      <%= for subtask <- Enum.filter(@subtasks, & &1.parent_task_id == @parent_task.id) do %>
        <.subtask_list_items subtask={subtask} navigate_fn={@navigate_fn} patch_fn={@patch_fn} />
      <% end %>
    </ul>
    """
  end

  def task_list_items(assigns) do
    ~H"""
    <li class="border border-gray-600 p-4 rounded-lg">
      <div class="flex items-center justify-between gap-1">
        <div class="flex items-center gap-1 truncate mb-2">
          <.button
            :if={Enum.any?(@subtasks, &(&1.parent_task_id == @parent_task.id))}
            phx-click={
              JS.toggle(
                to: "#dropdown_id_#{@parent_task.id}",
                in: {"ease-out duration-100", "opacity-0 scale-95", "opacity-100 scale-100"},
                out: {"ease-out duration-75", "opacity-100 scale-100", "opacity-0 scale-95"}
              )
              |> JS.toggle_class("rotate-90", to: "#chevron_id_#{@parent_task.id}")
            }
          >
            <.icon
              name="hero-chevron-right"
              id={"chevron_id_#{@parent_task.id}"}
              class="bg-brand-700 h-6 w-6"
            />
          </.button>
          <.link
            navigate={@navigate_fn.(@parent_task)}
            class="font-semibold tracking-tighter truncate"
          >
            <p class="flex items-center gap-2">
              <%= @parent_task.title %>
              <.icon name="hero-information-circle" class="text-gray-700" />
            </p>
          </.link>
        </div>
        <div class="flex items-center gap-1">
          <.check_task subtasks={@subtasks} task={@parent_task} />
          <.link patch={@patch_fn.(@parent_task)}>
            <.button
              phx-click={JS.push("add_subtask", value: %{parent_id: @parent_task.id})}
              class="rounded-full border-brand-700 border-2 h-6 w-6 flex items-center justify-center"
            >
              <.icon name="hero-plus" class="text-brand-700" />
            </.button>
          </.link>
        </div>
      </div>
      <div class="grid sm:grid-cols-2 sm:gap-1 text-sm">
        <.item_slot label={gettext("Description")}><%= @parent_task.description %></.item_slot>
        <.item_slot label={gettext("Due date")}><%= @parent_task.due_date %></.item_slot>
        <.item_slot label={gettext("Status")}>
          <%= TaskMasterWeb.Helpers.EnumTranslator.translate_enum_value(@parent_task.status) %>
        </.item_slot>
        <.item_slot label={gettext("Duration")}>
          <%= TaskMasterWeb.Helpers.Formatted.format_duration(@parent_task.duration) %>
        </.item_slot>
        <.item_slot label={gettext("Priority")}>
          <%= TaskMasterWeb.Helpers.EnumTranslator.translate_enum_value(@parent_task.priority) %>
        </.item_slot>
        <.item_slot label={gettext("Indoor")}>
          <%= TaskMasterWeb.Helpers.IconHelper.boolean_icon(@parent_task.indoor) %>
        </.item_slot>
        <.item_slot label={gettext("Who?")}>
          <%= for participant <- Enum.sort_by(@parent_task.participants, & &1.nick_name) do %>
            <.nick_name participant={participant.nick_name} />
          <% end %>
        </.item_slot>
      </div>
      <.subtask_list
        parent_task={@parent_task}
        subtasks={@subtasks}
        navigate_fn={@navigate_fn}
        patch_fn={@patch_fn}
      />
    </li>
    """
  end

  def subtask_list_items(assigns) do
    ~H"""
    <li class="border border-gray-300 p-2 rounded">
      <div class="flex justify-between">
        <.link navigate={@navigate_fn.(@subtask)} class="font-medium">
          <%= @subtask.title %>
        </.link>
        <.check_task task={@subtask} />
      </div>
      <div class="grid grid-cols-2 gap-2 text-sm mt-2">
        <.item_slot label={gettext("Description")}><%= @subtask.description %></.item_slot>
        <.item_slot label={gettext("Due date")}><%= @subtask.due_date %></.item_slot>
        <.item_slot label={gettext("Status")}>
          <%= TaskMasterWeb.Helpers.EnumTranslator.translate_enum_value(@subtask.status) %>
        </.item_slot>
        <.item_slot label={gettext("Duration")}>
          <%= TaskMasterWeb.Helpers.Formatted.format_duration(@subtask.duration) %>
        </.item_slot>
        <.item_slot label={gettext("Priority")}>
          <%= TaskMasterWeb.Helpers.EnumTranslator.translate_enum_value(@subtask.priority) %>
        </.item_slot>
        <.item_slot label={gettext("Indoor")}>
          <%= TaskMasterWeb.Helpers.IconHelper.boolean_icon(@subtask.indoor) %>
        </.item_slot>
        <.item_slot label={gettext("Who?")}>
          <%= for participant <- Enum.sort_by(@subtask.participants, & &1.nick_name) do %>
            <.nick_name participant={participant.nick_name} />
          <% end %>
        </.item_slot>
      </div>
    </li>
    """
  end

  attr(:label, :string, required: true)
  slot(:inner_block, required: true)

  def item_slot(assigns) do
    ~H"""
    <div>
      <strong><%= @label %>:</strong> <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:parent_task, :any, default: nil)
  attr(:subtasks, :list, default: [])
  attr(:task, :any, required: true)

  def check_task(assigns) do
    ~H"""
    <.button
      :if={Enum.empty?(@subtasks) || Enum.all?(@subtasks, &(&1.parent_task_id != @task.id))}
      phx-click={JS.push("toggle_task_status", value: %{id: @task.id, current_status: @task.status})}
      class="flex items-center justify-center"
    >
      <.icon
        name="hero-check-circle"
        class={"h-8 w-8 " <>if @task.status == :completed, do: "text-green-500", else: "text-red-300"}
      />
    </.button>
    """
  end
end
