defmodule Jido.Chat.Telegram.DocumentOptions do
  @moduledoc """
  Typed options for Telegram `send_document/3`.
  """

  alias Jido.Chat.Telegram.Transport.ExGramClient

  @schema Zoi.struct(
            __MODULE__,
            %{
              token: Zoi.string() |> Zoi.nullish(),
              transport: Zoi.any() |> Zoi.default(ExGramClient),
              caption: Zoi.string() |> Zoi.nullish(),
              parse_mode: Zoi.string() |> Zoi.nullish(),
              reply_markup: Zoi.any() |> Zoi.nullish(),
              thread_id: Zoi.any() |> Zoi.nullish(),
              disable_notification: Zoi.boolean() |> Zoi.nullish(),
              debug: Zoi.boolean() |> Zoi.nullish(),
              check_params: Zoi.boolean() |> Zoi.nullish(),
              ex_gram_module: Zoi.any() |> Zoi.nullish(),
              ex_gram_adapter: Zoi.any() |> Zoi.nullish()
            },
            coerce: true
          )

  @type t :: unquote(Zoi.type_spec(@schema))

  @enforce_keys Zoi.Struct.enforce_keys(@schema)
  defstruct Zoi.Struct.struct_fields(@schema)

  @doc "Returns the Zoi schema for document options."
  def schema, do: @schema

  @doc "Builds typed document options from keyword/map/struct input."
  def new(%__MODULE__{} = opts), do: opts
  def new(opts) when is_list(opts), do: opts |> Map.new() |> new()
  def new(opts) when is_map(opts), do: Jido.Chat.Schema.parse!(__MODULE__, @schema, opts)

  @doc "Builds Telegram API payload options for `sendDocument`."
  @spec payload_opts(t()) :: map()
  def payload_opts(%__MODULE__{} = opts) do
    %{}
    |> maybe_put("caption", opts.caption)
    |> maybe_put("parse_mode", opts.parse_mode)
    |> maybe_put("reply_markup", opts.reply_markup)
    |> maybe_put("message_thread_id", opts.thread_id)
    |> maybe_put("disable_notification", opts.disable_notification)
  end

  @doc "Builds transport-level options consumed by `ExGramClient`."
  @spec transport_opts(t()) :: keyword()
  def transport_opts(%__MODULE__{} = opts) do
    []
    |> maybe_kw(:debug, opts.debug)
    |> maybe_kw(:check_params, opts.check_params)
    |> maybe_kw(:ex_gram_module, opts.ex_gram_module)
    |> maybe_kw(:ex_gram_adapter, opts.ex_gram_adapter)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_kw(keyword, _key, nil), do: keyword
  defp maybe_kw(keyword, key, value), do: Keyword.put(keyword, key, value)
end
