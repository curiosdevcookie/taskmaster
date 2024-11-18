defmodule TaskMaster.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  import TaskMasterWeb.Gettext

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "users" do
    field :first_name, :string
    field :last_name, :string
    field :nick_name, :string
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :naive_datetime
    field :last_login_at, :naive_datetime
    field :organization_name, :string, virtual: true
    field :stars, :integer, default: 0
    has_one :avatar, TaskMaster.Accounts.Avatar
    has_many :task_participations, TaskMaster.Tasks.TaskParticipation
    belongs_to :organization, TaskMaster.Accounts.Organization, type: :binary_id

    timestamps()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [
      :first_name,
      :last_name,
      :nick_name,
      :email,
      :password,
      :organization_name,
      :organization_id
    ])
    |> validate_required([:first_name, :last_name, :nick_name])
    |> validate_email(opts)
    |> validate_password(opts)
    |> unique_constraint(:email)
    |> unique_constraint(:nick_name)
    |> validate_organization()
  end

  def stars_changeset(user, attrs) do
    user
    |> cast(attrs, [:stars])
    |> validate_number(:stars, greater_than_or_equal_to: 0)
  end

  defp validate_organization(changeset) do
    org_id = get_change(changeset, :organization_id)
    org_name = get_change(changeset, :organization_name)

    cond do
      is_binary(org_id) -> changeset
      is_binary(org_name) -> changeset
      true -> add_error(changeset, :organization, "Organization ID or name must be provided")
    end
  end

  def change_user(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:first_name, :last_name, :nick_name, :email, :organization_id])
    |> validate_required([:first_name, :last_name, :nick_name, :email])
    |> validate_email([])
    |> unique_constraint(:email)
    |> unique_constraint(:nick_name)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
      message: gettext("must have the @ sign and no spaces")
    )
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    |> validate_format(:password, ~r/[a-z]/,
      message: gettext("at least one lower case character")
    )
    |> validate_format(:password, ~r/[A-Z]/,
      message: gettext("at least one upper case character")
    )
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/,
      message: gettext("at least one digit or punctuation character")
    )
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, TaskMaster.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, gettext("did not change"))
    end
  end

  @doc """
  A user changeset for changing the nick_name.

  It requires the current password to be provided and it should match the
  password being set.
  """

  def nick_name_changeset(user, attrs) do
    user
    |> cast(attrs, [:nick_name])
    |> validate_required([:nick_name])
    |> unique_constraint(:nick_name)
  end


  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: gettext("does not match password"))
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%TaskMaster.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, gettext("is not valid"))
    end
  end
end
