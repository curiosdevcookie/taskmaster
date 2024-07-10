defmodule TaskMasterWeb.Helpers.EnumTranslator do
  import TaskMasterWeb.Gettext

  def translate_enum(enum_module, field) do
    Ecto.Enum.values(enum_module, field)
    |> Enum.map(fn value ->
      {translate_enum_value(value), value}
    end)
  end

  def translate_enum_value(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
    |> translate_enum_value()
  end

  def translate_enum_value(value) when is_binary(value) do
    case value do
      "Open" -> gettext("Open")
      "Progressing" -> gettext("Progressing")
      "Completed" -> gettext("Completed")
      "Low" -> gettext("Low")
      "Medium" -> gettext("Medium")
      "High" -> gettext("High")
      _ -> value
    end
  end
end
