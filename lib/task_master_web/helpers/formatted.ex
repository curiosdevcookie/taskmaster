defmodule TaskMasterWeb.Helpers.Formatted do
  def downcase(value) do
    value
    |> String.downcase()
  end

  def uppercase(value) do
    value
    |> String.upcase()
  end

  def capitalize(value) do
    value
    |> String.capitalize()
  end

  def format_duration(duration) when is_number(duration) do
    abs(duration)
  end

  def format_duration(_), do: 0
end
