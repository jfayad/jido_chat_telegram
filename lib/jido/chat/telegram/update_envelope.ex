defmodule Jido.Chat.Telegram.UpdateEnvelope do
  @moduledoc """
  Typed Telegram update envelope for extension-level ingest.
  """

  alias Jido.Chat.Wire

  @update_types [
    :message,
    :edited_message,
    :channel_post,
    :edited_channel_post,
    :callback_query,
    :message_reaction,
    :noop,
    :unsupported
  ]

  @schema Zoi.struct(
            __MODULE__,
            %{
              id: Zoi.string(),
              update_id: Zoi.integer() |> Zoi.nullish(),
              update_type: Zoi.enum(@update_types),
              payload: Zoi.any() |> Zoi.nullish(),
              raw: Zoi.map() |> Zoi.default(%{}),
              metadata: Zoi.map() |> Zoi.default(%{})
            },
            coerce: true
          )

  @type t :: unquote(Zoi.type_spec(@schema))

  @enforce_keys Zoi.Struct.enforce_keys(@schema)
  defstruct Zoi.Struct.struct_fields(@schema)

  @doc "Returns the Zoi schema for UpdateEnvelope."
  def schema, do: @schema

  @doc "Creates a Telegram update envelope."
  @spec new(map()) :: t()
  def new(attrs) when is_map(attrs) do
    attrs
    |> Map.put_new(:id, Jido.Chat.ID.generate!())
    |> then(&Jido.Chat.Schema.parse!(__MODULE__, @schema, &1))
  end

  @doc "Serializes update envelope into a plain map with type marker."
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = envelope) do
    envelope
    |> Map.from_struct()
    |> Wire.to_plain()
    |> Map.put("__type__", "telegram_update_envelope")
  end

  @doc "Builds update envelope from serialized map data."
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map), do: new(map)
end
