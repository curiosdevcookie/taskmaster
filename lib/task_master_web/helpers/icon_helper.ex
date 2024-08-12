defmodule TaskMasterWeb.Helpers.IconHelper do
  use Phoenix.HTML

  def boolean_icon(true), do: content_tag(:span, "🏠", class: "text-green-500")
  def boolean_icon(false), do: content_tag(:span, "☀️", class: "text-red-500")
end
