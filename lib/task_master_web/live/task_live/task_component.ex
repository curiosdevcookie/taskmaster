defmodule TaskMasterWeb.TaskLive.TaskComponent do
  use TaskMasterWeb, :live_component

  alias TaskMaster.Tasks

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          <%= gettext("Use this form to manage task records in your database.") %>
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="task-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <input type="hidden" name="task[created_by]" value={@current_user.id} />
        <.input field={@form[:title]} type="text" label={gettext("Title")} />
        <.input field={@form[:description]} type="text" label={gettext("Description")} />
        <.input field={@form[:due_date]} type="date" label={gettext("Due date")} />
        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          prompt={gettext("Choose a value")}
          options={
            TaskMasterWeb.Helpers.EnumTranslator.translate_enum(TaskMaster.Tasks.Task, :status)
          }
        />
        <.input field={@form[:duration]} type="number" label={gettext("Duration")} />
        <.input
          field={@form[:priority]}
          type="select"
          label={gettext("Priority")}
          prompt={gettext("Choose a value")}
          options={
            TaskMasterWeb.Helpers.EnumTranslator.translate_enum(TaskMaster.Tasks.Task, :priority)
          }
        />
        <.input field={@form[:indoor]} type="checkbox" label={gettext("Indoor")} />
        <:actions>
          <.button phx-disable-with="Saving..."><%= gettext("Save") %></.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{task: task} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(Tasks.change_task(task))}
  end

  @impl true
  def handle_event("validate", %{"task" => task_params}, socket) do
    changeset =
      socket.assigns.task
      |> Tasks.change_task(task_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"task" => task_params}, socket) do
    save_task(socket, socket.assigns.action, task_params)
  end

  defp save_task(socket, :edit, task_params) do
    case Tasks.update_task(socket.assigns.task, task_params) do
      {:ok, task} ->
        notify_parent({:saved, task})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Task updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_task(socket, :new, task_params) do
    case Tasks.create_task(task_params) do
      {:ok, task} ->
        notify_parent({:saved, task})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Task created successfully"))
         |> push_navigate(to: ~p"/#{socket.assigns.current_user.id}/tasks")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
