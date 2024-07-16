defmodule TaskMasterWeb.TaskLive.TaskShow do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Tasks

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    task = Tasks.get_task!(id) |> Tasks.preload_task_participants()

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:task, task)}
  end

  defp page_title(:show), do: "Show Task"
  defp page_title(:edit), do: "Edit Task"

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= gettext("Task") %>
      <:subtitle><%= gettext("This is a task record from your database.") %></:subtitle>
      <:actions>
        <.link patch={~p"/#{@current_user.id}/tasks/#{@task}/show/edit"} phx-click={JS.push_focus()}>
          <.button><%= gettext("Edit task") %></.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title={gettext("Title")}><%= @task.title %></:item>
      <:item title={gettext("Description")}><%= @task.description %></:item>
      <:item title={gettext("Due date")}><%= @task.due_date %></:item>
      <:item title={gettext("Status")}>
        <%= TaskMasterWeb.Helpers.EnumTranslator.translate_enum_value(@task.status) %>
      </:item>
      <:item title={gettext("Duration")}><%= @task.duration %></:item>
      <:item title={gettext("Priority")}>
        <%= TaskMasterWeb.Helpers.EnumTranslator.translate_enum_value(@task.priority) %>
      </:item>
      <:item title={gettext("Indoor")}>
        <%= TaskMasterWeb.Helpers.IconHelper.boolean_icon(@task.indoor) %>
      </:item>
      <:item title={gettext("Participants")}>
        <div class="flex flex-wrap gap-2">
          <%= for participant <- @task.participants do %>
            <span class="px-2 py-1 text-sm font-semibold text-blue-800 bg-blue-100 rounded-full">
              <%= if participant.nick_name do %>
                <%= participant.nick_name %>
              <% else %>
                <%= participant.first_name %>
              <% end %>
            </span>
          <% end %>
        </div>
      </:item>
    </.list>

    <.back navigate={~p"/#{@current_user.id}/tasks"}><%= gettext("Back") %></.back>

    <.modal
      :if={@live_action == :edit}
      id="task-modal"
      show
      on_cancel={JS.patch(~p"/#{@current_user.id}/tasks/#{@task}")}
    >
      <.live_component
        module={TaskMasterWeb.TaskLive.TaskComponent}
        id={@task.id}
        title={@page_title}
        action={@live_action}
        task={@task}
        current_user={@current_user}
        patch={~p"/#{@current_user.id}/tasks/#{@task}"}
      />
    </.modal>
    """
  end
end
