defmodule UnifiedUi.Dsl.FormHelpers do
  @moduledoc """
  Helper functions for working with forms in the UnifiedUi DSL.

  Forms are implicit groups of input widgets that share a common `form_id`.
  This module provides utilities for collecting form data, building form
  submission signals, and validating form data.

  ## Form Association

  Inputs are associated with forms using the `form_id` option:

      ui do
        text_input :email, form_id: :login
        text_input :password, form_id: :login, type: :password
        button "Submit", on_click: {:submit_login, %{form_id: :login}}
      end

  ## Data Collection

  Collect form data from the DSL state:

      def update(:submit_login, %{form_id: form_id}, state) do
        form_data = UnifiedUi.Dsl.FormHelpers.collect_form_data(__dsl_state__, form_id)
        # form_data => %{email: "user@example.com", password: "secret"}
        {:noreply, state}
      end

  ## Validation

  Validate form data using the provided validators:

      case validate_required(form_data, [:email, :password]) do
        :ok ->
          case validate_email(form_data, :email) do
            :ok -> process_form(form_data)
            {:error, _} -> show_error()
          end
        {:error, _} -> show_error()
      end

  """

  alias Spark.Dsl.Transformer
  alias UnifiedUi.IUR.Widgets.TextInput

  @doc """
  Collects all input values for a given form_id from the DSL state.

  Returns a map where keys are input IDs and values are the input's value field.

  ## Parameters

  * `dsl_state` - The Spark DSL state (available as `__dsl_state__` in update/2)
  * `form_id` - The form identifier to collect data for

  ## Returns

  A map of `%{input_id => value}` for all inputs with the given form_id.

  ## Examples

      iex> collect_form_data(dsl_state, :login)
      %{email: "user@example.com", password: "secret123"}

  If no inputs match the form_id, returns an empty map:

      iex> collect_form_data(dsl_state, :nonexistent)
      %{}

  """
  @spec collect_form_data(map(), atom()) :: map()
  def collect_form_data(dsl_state, form_id) when is_atom(form_id) do
    dsl_state
    |> Transformer.get_entities(:widgets)
    |> Enum.filter(&form_input?(&1, form_id))
    |> Enum.map(fn input ->
      {input.id, Map.get(input, :value)}
    end)
    |> Map.new()
  end

  @doc """
  Returns a list of all input IDs that belong to the given form.

  Useful for form validation to know which fields to check.

  ## Parameters

  * `dsl_state` - The Spark DSL state
  * `form_id` - The form identifier

  ## Returns

  A list of input IDs (atoms) that have the given form_id.

  ## Examples

      iex> form_input_ids(dsl_state, :login)
      [:email, :password]

  """
  @spec form_input_ids(map(), atom()) :: [atom()]
  def form_input_ids(dsl_state, form_id) when is_atom(form_id) do
    dsl_state
    |> Transformer.get_entities(:widgets)
    |> Enum.filter(&form_input?(&1, form_id))
    |> Enum.map(& &1.id)
  end

  @doc """
  Builds a form submission signal tuple.

  The signal format is `{:form_submit, %{form_id: form_id, data: data}}`.

  ## Parameters

  * `form_id` - The form identifier
  * `data` - The form data map (from collect_form_data/2)
  * `extra_payload` - Optional additional payload data to merge

  ## Returns

  A signal tuple that can be returned from update/2.

  ## Examples

      iex> build_form_submit_signal(:login, %{email: "...", password: "..."})
      {:form_submit, %{form_id: :login, data: %{email: "...", password: "..."}}}

      iex> build_form_submit_signal(:login, %{email: "..."}, %{timestamp: 123})
      {:form_submit, %{form_id: :login, data: %{email: "..."}, timestamp: 123}}

  """
  @spec build_form_submit_signal(atom(), map(), map() | nil) :: {:form_submit, map()}
  def build_form_submit_signal(form_id, data, extra_payload \\ nil)
      when is_atom(form_id) and is_map(data) do
    base_payload = %{
      form_id: form_id,
      data: data
    }

    payload =
      if is_map(extra_payload) do
        Map.merge(base_payload, extra_payload)
      else
        base_payload
      end

    {:form_submit, payload}
  end

  @doc """
  Validates that all required fields are present and non-empty in the form data.

  A field is considered present if it exists in the map and its value is
  not nil or an empty string.

  ## Parameters

  * `form_data` - The form data map (from collect_form_data/2)
  * `required_fields` - List of field keys (atoms) that must be present

  ## Returns

  * `:ok` - All required fields are present and non-empty
  * `{:error, missing_fields}` - List of fields that are missing or empty

  ## Examples

      iex> validate_required(%{email: "test@example.com", password: "secret"}, [:email, :password])
      :ok

      iex> validate_required(%{email: "test@example.com"}, [:email, :password])
      {:error, [:password]}

      iex> validate_required(%{email: "", password: "secret"}, [:email, :password])
      {:error, [:email]}

  """
  @spec validate_required(map(), [atom()]) :: :ok | {:error, [atom()]}
  def validate_required(form_data, required_fields) when is_map(form_data) and is_list(required_fields) do
    missing =
      required_fields
      |> Enum.filter(fn field ->
        value = Map.get(form_data, field)
        is_nil(value) or value == ""
      end)

    case missing do
      [] -> :ok
      _ -> {:error, missing}
    end
  end

  @doc """
  Validates that an email field has a valid email format.

  This is a basic validation that checks for:
  - Contains @ symbol
  - Has characters before @
  - Has characters after @
  - Has at least one . after @

  For production use, consider a more robust email validation library.

  ## Parameters

  * `form_data` - The form data map
  * `field` - The field key (atom) to validate

  ## Returns

  * `:ok` - The field has a valid email format
  * `{:error, :invalid_format}` - The field is not a valid email
  * `{:error, :missing}` - The field is not present in the form data

  ## Examples

      iex> validate_email(%{email: "user@example.com"}, :email)
      :ok

      iex> validate_email(%{email: "invalid"}, :email)
      {:error, :invalid_format}

      iex> validate_email(%{}, :email)
      {:error, :missing}

  """
  @spec validate_email(map(), atom()) :: :ok | {:error, atom()}
  def validate_email(form_data, field) when is_map(form_data) and is_atom(field) do
    case Map.get(form_data, field) do
      nil ->
        {:error, :missing}

      value when is_binary(value) ->
        if valid_email_format?(value) do
          :ok
        else
          {:error, :invalid_format}
        end

      _ ->
        {:error, :invalid_format}
    end
  end

  @doc """
  Validates that a field's value length is within the specified range.

  ## Parameters

  * `form_data` - The form data map
  * `field` - The field key (atom) to validate
  * `min_length` - Minimum allowed length (use 0 for no minimum)
  * `max_length` - Maximum allowed length (use :infinity for no maximum)

  ## Returns

  * `:ok` - The field length is within the specified range
  * `{:error, :too_short}` - The field is shorter than min_length
  * `{:error, :too_long}` - The field is longer than max_length
  * `{:error, :missing}` - The field is not present in the form data

  ## Examples

      iex> validate_length(%{username: "john_doe"}, :username, 3, 20)
      :ok

      iex> validate_length(%{username: "jo"}, :username, 3, 20)
      {:error, :too_short}

      iex> validate_length(%{username: "this_is_a_very_long_username"}, :username, 3, 10)
      {:error, :too_long}

      iex> validate_length(%{username: String.duplicate("a", 100)}, :username, 0, :infinity)
      :ok

  """
  @spec validate_length(map(), atom(), non_neg_integer(), non_neg_integer() | :infinity) ::
          :ok | {:error, atom()}
  def validate_length(form_data, field, min_length, max_length \\ :infinity)
      when is_map(form_data) and is_atom(field) and is_integer(min_length) do
    case Map.get(form_data, field) do
      nil ->
        {:error, :missing}

      value when is_binary(value) ->
        length = String.length(value)

        cond do
          length < min_length ->
            {:error, :too_short}

          max_length != :infinity and length > max_length ->
            {:error, :too_long}

          true ->
            :ok
        end

      _ ->
        {:error, :invalid_type}
    end
  end

  @doc """
  Validates that a field's value matches a regular expression pattern.

  ## Parameters

  * `form_data` - The form data map
  * `field` - The field key (atom) to validate
  * `pattern` - A regex pattern to match against (as a string or Regex struct)

  ## Returns

  * `:ok` - The field matches the pattern
  * `{:error, :invalid_format}` - The field does not match the pattern
  * `{:error, :missing}` - The field is not present in the form data

  ## Examples

      iex> validate_format(%{zip: "12345"}, :zip, ~r/^\\d{5}$/)
      :ok

      iex> validate_format(%{zip: "ABCDE"}, :zip, ~r/^\\d{5}$/)
      {:error, :invalid_format}

      iex> validate_format(%{username: "john123"}, :username, ~r/^[a-z0-9_]+$/i)
      :ok

  """
  @spec validate_format(map(), atom(), Regex.t() | String.t()) :: :ok | {:error, atom()}
  def validate_format(form_data, field, pattern)
      when is_map(form_data) and is_atom(field) do
    regex = if is_binary(pattern), do: Regex.compile!(pattern), else: pattern

    case Map.get(form_data, field) do
      nil ->
        {:error, :missing}

      value when is_binary(value) ->
        if Regex.match?(regex, value) do
          :ok
        else
          {:error, :invalid_format}
        end

      _ ->
        {:error, :invalid_type}
    end
  end

  @doc """
  Validates multiple fields and returns all errors together.

  This is useful for showing all validation errors at once rather than
  failing on the first error.

  ## Parameters

  * `form_data` - The form data map
  * `validations` - A list of validation tuples to run

  ## Validation Tuples

  Each validation is a tuple with one of these formats:
  * `{:required, field}` - Validate field is present and non-empty
  * `{:email, field}` - Validate field has email format
  * `{:length, field, min, max}` - Validate field length
  * `{:format, field, pattern}` - Validate field matches regex

  ## Returns

  * `:ok` - All validations passed
  * `{:error, errors}` - Map of field => error_reason

  ## Examples

      iex> validate_form(%{email: "bad", password: "pass"}, [
      ...>   {:required, :email},
      ...>   {:required, :password},
      ...>   {:email, :email},
      ...>   {:length, :password, 8}
      ...> ])
      {:error, %{email: :invalid_format, password: :too_short}}

  """
  @spec validate_form(map(), list()) :: :ok | {:error, map()}
  def validate_form(form_data, validations) when is_map(form_data) and is_list(validations) do
    errors =
      validations
      |> Enum.reduce([], fn validation, acc ->
        case run_validation(form_data, validation) do
          :ok -> acc
          {:error, {_field, _reason} = error} -> [error | acc]
          {:error, field} when is_atom(field) -> [{field, :invalid} | acc]
        end
      end)
      |> Enum.reverse()
      |> Map.new()

    case map_size(errors) do
      0 -> :ok
      _ -> {:error, errors}
    end
  end

  # Private helpers

  defp form_input?(entity, form_id) do
    entity.__struct__ == TextInput and Map.get(entity, :form_id) == form_id
  end

  defp valid_email_format?(email) when is_binary(email) do
    # Basic email validation: contains @, has chars before and after, has a . after @
    case String.split(email, "@") do
      [local, domain] ->
        String.length(local) > 0 and String.length(domain) > 0 and
          String.contains?(domain, ".")

      _ ->
        false
    end
  end

  defp run_validation(form_data, {:required, field}) do
    case validate_required(form_data, [field]) do
      :ok -> :ok
      {:error, [^field]} -> {:error, {field, :required}}
      _ -> :ok
    end
  end

  defp run_validation(form_data, {:email, field}) do
    case validate_email(form_data, field) do
      :ok -> :ok
      {:error, reason} -> {:error, {field, reason}}
    end
  end

  defp run_validation(form_data, {:length, field, min, max}) do
    case validate_length(form_data, field, min, max) do
      :ok -> :ok
      {:error, reason} -> {:error, {field, reason}}
    end
  end

  defp run_validation(form_data, {:length, field, min}) do
    case validate_length(form_data, field, min, :infinity) do
      :ok -> :ok
      {:error, reason} -> {:error, {field, reason}}
    end
  end

  defp run_validation(form_data, {:format, field, pattern}) do
    case validate_format(form_data, field, pattern) do
      :ok -> :ok
      {:error, reason} -> {:error, {field, reason}}
    end
  end
end
