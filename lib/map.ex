defmodule Skooma.Map do
  alias Skooma.Utils

  def validate_map(data, schema) do
    with :ok <- is_map(data) |> Utils.to_result("Data is not a map"),
         :ok <- key_handler(data, schema),
         :ok <- value_handler(data, schema),
         do: :ok
  end

  defp key_handler(data, schema) do
    schema
    |> Enum.map(&get_required_keys/1)
    |> Enum.reject(&is_nil/1)
    |> validate_keys(data)
  end

  defp get_required_keys({k, v}) do
    if is_atom(v) do
      k
    else
      if (Enum.member?(v, :not_required)), do: nil, else: k
    end
  end

  defp validate_keys(required_keys, data) do
    missing_keys = required_keys -- Map.keys(data)
    if Enum.count(missing_keys) == 0 do
      :ok
    else
      {:error, "Missing required keys: #{inspect missing_keys}"}
    end
  end

  defp value_handler(data, schema) do
    results = Enum.map(data, &(validate_child(&1, schema)))
    |> Enum.filter(&(&1 != :ok))

    if Enum.count(results) == 0 do
      :ok
    else
      results
    end
  end

  defp validate_child({k, v}, schema) do
    if schema[k] |> is_nil do
      :ok
    else
      Skooma.valid?(v, schema[k])
    end
  end

  def nested_map(data, parent_schema) do
    schema = Enum.find(parent_schema, &is_function/1)
    clean_schema = if schema,  do: schema.(), else: Enum.find(parent_schema, &is_map/1)
    Skooma.valid?(data, clean_schema)
  end
end
