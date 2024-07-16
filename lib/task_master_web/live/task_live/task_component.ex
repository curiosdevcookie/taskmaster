defmodule TaskMasterWeb.TaskLive.TaskComponent do
  use TaskMasterWeb, :live_component

  alias TaskMaster.Tasks
  alias TaskMaster.Accounts

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

        <div class="mb-4">
          <label class="block text-sm font-medium text-gray-700">
            <%= gettext("Participants") %>
          </label>
          <div class="mt-2 flex flex-wrap gap-2">
            <%= for participant <- @participants do %>
              <div class="flex items-center bg-blue-100 rounded-full px-3 py-1">
                <span class="text-sm text-blue-800">
                  <%= participant.first_name %> <%= participant.last_name %>
                </span>
                <button
                  type="button"
                  phx-click="remove_participant"
                  phx-value-id={participant.id}
                  phx-target={@myself}
                  class="ml-2 text-blue-600 hover:text-blue-800"
                >
                  &times;
                </button>
              </div>
            <% end %>
          </div>
        </div>

        <div class="mb-4">
          <.input
            id="participant-select"
            name="participant"
            type="select"
            label={gettext("Add Participant")}
            prompt={gettext("Select a user")}
            options={
              Enum.map(@available_users, fn user ->
                {user.first_name <> " " <> user.last_name, user.id}
              end)
            }
            value={@selected_participant_id |> dbg()}
            phx-change="select_participant"
            phx-target={@myself}
          />
          <button
            type="button"
            phx-click="add_participant"
            phx-target={@myself}
            phx-value-id={@selected_participant_id}
            class="ml-2 inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <%= gettext("Add") %>
          </button>
        </div>

        <:actions>
          <.button phx-disable-with="Saving..."><%= gettext("Save") %></.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{task: task} = assigns, socket) do
    changeset = Tasks.change_task(task)
    participants = Tasks.list_task_participants(task.id)
    all_users = Accounts.list_users()
    available_users = all_users -- participants

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:participants, participants)
     |> assign(:available_users, available_users)
     |> assign(:selected_participant_id, nil)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"task" => task_params}, socket) do
    changeset =
      socket.assigns.task
      |> Tasks.change_task(task_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"task" => task_params}, socket) do
    save_task(socket, socket.assigns.action, task_params)
  end

  @impl true
  def handle_event("select_participant", %{"participant" => user_id}, socket) do
    {:noreply, assign(socket, :selected_participant_id, user_id)}
  end

  @impl true
  def handle_event("add_participant", _params, socket) do
    case socket.assigns.selected_participant_id do
      nil ->
        {:noreply, put_flash(socket, :error, "Please select a user to add")}

      user_id ->
        case Accounts.get_user!(user_id) do
          nil ->
            {:noreply, put_flash(socket, :error, "Selected user not found")}

          user ->
            updated_participants = [user | socket.assigns.participants]
            updated_available_users = socket.assigns.available_users -- [user]

            {:noreply,
             socket
             |> assign(:participants, updated_participants)
             |> assign(:available_users, updated_available_users)
             |> assign(:selected_participant_id, nil)
             |> put_flash(:info, "Participant added successfully")}
        end
    end
  end

  @impl true
  def handle_event("remove_participant", %{"id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)
    updated_participants = socket.assigns.participants -- [user]
    updated_available_users = [user | socket.assigns.available_users]

    {:noreply,
     socket
     |> assign(:participants, updated_participants)
     |> assign(:available_users, updated_available_users)}
  end

  defp save_task(socket, :edit, task_params) do
    case Tasks.update_task(socket.assigns.task, task_params) do
      {:ok, task} ->
        Tasks.update_task_participants(task, socket.assigns.participants)
        notify_parent({:saved, task})

        {:noreply,
         socket
         |> put_flash(:info, "Task updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_task(socket, :new, task_params) do
    case Tasks.create_task(task_params) do
      {:ok, task} ->
        Tasks.update_task_participants(task, socket.assigns.participants)
        notify_parent({:saved, task})

        {:noreply,
         socket
         |> put_flash(:info, "Task created successfully")
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
