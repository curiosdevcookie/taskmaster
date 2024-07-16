defmodule TaskMasterWeb.TaskLive.TaskIndex do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Tasks
  alias TaskMaster.Tasks.Task
  import TaskMasterWeb.Components.TaskComponents

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    tasks = Tasks.list_tasks_with_participants()

    socket
    |> assign(:current_user, current_user)
    |> assign(:page_title, gettext("Listing Tasks"))
    |> stream(:tasks, tasks)
    |> ok()
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Task"))
    |> assign(:task, Tasks.get_task!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Task"))
    |> assign(:task, %Task{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Tasks"))
    |> assign(:task, nil)
  end

  @impl true
  def handle_info({TaskMasterWeb.TaskLive.TaskComponent, {:saved, task}}, socket) do
    updated_task = Tasks.get_task!(task.id) |> Tasks.preload_task_participants()
    {:noreply, stream_insert(socket, :tasks, updated_task)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    task = Tasks.get_task!(id)
    {:ok, _} = Tasks.delete_task(task)

    {:noreply, stream_delete(socket, :tasks, task)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= gettext("Listing Tasks") %>
      <:actions>
        <.link patch={~p"/#{@current_user.id}/tasks/new"}>
          <.button><%= gettext("New Task") %></.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="tasks"
      rows={@streams.tasks}
      row_click={fn {_id, task} -> JS.navigate(~p"/#{@current_user.id}/tasks/#{task}") end}
    >
      <:col :let={{_id, task}} label={gettext("Title")}><%= task.title %></:col>
      <:col :let={{_id, task}} label={gettext("Description")}><%= task.description %></:col>
      <:col :let={{_id, task}} label={gettext("Due date")}><%= task.due_date %></:col>
      <:col :let={{_id, task}} label={gettext("Status")}>
        <%= TaskMasterWeb.Helpers.EnumTranslator.translate_enum_value(task.status) %>
      </:col>
      <:col :let={{_id, task}} label={gettext("Duration")}><%= task.duration %></:col>
      <:col :let={{_id, task}} label={gettext("Priority")}>
        <%= TaskMasterWeb.Helpers.EnumTranslator.translate_enum_value(task.priority) %>
      </:col>
      <:col :let={{_id, task}} label={gettext("Indoor")}>
        <%= TaskMasterWeb.Helpers.IconHelper.boolean_icon(task.indoor) %>
      </:col>
      <:col :let={{_id, task}} label={gettext("Who?")}>
        <div class="flex flex-wrap gap-1">
          <%= for participant <- task.participants do %>
            <.nick_name participant={participant.nick_name} />
          <% end %>
        </div>
      </:col>
      <:action :let={{_id, task}}>
        <div class="sr-only">
          <.link navigate={~p"/#{@current_user.id}/tasks/#{task}"}><%= gettext("Show") %></.link>
        </div>
        <.link patch={~p"/#{@current_user.id}/tasks/#{task}/edit"}><%= gettext("Edit") %></.link>
      </:action>
      <:action :let={{id, task}}>
        <.link
          phx-click={JS.push("delete", value: %{id: task.id}) |> hide("##{id}")}
          data-confirm={gettext("Are you sure?")}
        >
          <%= gettext("Delete") %>
        </.link>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="task-modal"
      show
      on_cancel={JS.patch(~p"/#{@current_user.id}/tasks")}
    >
      <.live_component
        module={TaskMasterWeb.TaskLive.TaskComponent}
        id={@task.id || :new}
        title={@page_title}
        action={@live_action}
        task={@task}
        current_user={@current_user}
        patch={~p"/#{@current_user.id}/tasks"}
      />
    </.modal>
    """
  end
end
