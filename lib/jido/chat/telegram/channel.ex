defmodule Jido.Chat.Telegram.Channel do
  @moduledoc """
  Compatibility wrapper for legacy `Jido.Chat.Channel` integrations.

  New integrations should use `Jido.Chat.Telegram.Adapter`.
  """

  @behaviour Jido.Chat.Channel

  alias Jido.Chat.Telegram.Adapter

  @impl true
  defdelegate channel_type(), to: Adapter

  @doc "Returns Telegram extension capability statuses for non-core surfaces."
  @spec extension_capabilities() :: map()
  def extension_capabilities, do: Adapter.extension_capabilities()

  @impl true
  def capabilities do
    [
      :text,
      :image,
      :audio,
      :video,
      :file,
      :streaming,
      :typing,
      :message_edit,
      :message_delete,
      :reactions,
      :actions,
      :slash_commands,
      :webhook_secret
    ]
  end

  @impl true
  defdelegate transform_incoming(payload), to: Adapter

  @impl true
  defdelegate send_message(chat_id, text, opts), to: Adapter

  @impl true
  defdelegate edit_message(chat_id, message_id, text, opts), to: Adapter

  @doc "Deletes a message when supported by Telegram API permissions."
  @spec delete_message(String.t() | integer(), String.t() | integer(), keyword()) ::
          :ok | {:error, term()}
  defdelegate delete_message(chat_id, message_id, opts), to: Adapter

  @doc "Sends Telegram chat action (typing status)."
  @spec start_typing(String.t() | integer(), keyword()) :: :ok | {:error, term()}
  defdelegate start_typing(chat_id, opts), to: Adapter

  @doc "Fetches Telegram chat metadata and normalizes to `Jido.Chat.ChannelInfo`."
  @spec fetch_metadata(String.t() | integer(), keyword()) ::
          {:ok, Jido.Chat.ChannelInfo.t()} | {:error, term()}
  defdelegate fetch_metadata(chat_id, opts), to: Adapter

  @doc "Opens Telegram DM (maps to chat/user id)."
  @spec open_dm(String.t() | integer(), keyword()) ::
          {:ok, String.t() | integer()} | {:error, term()}
  defdelegate open_dm(user_id, opts), to: Adapter

  @doc "Posts ephemeral via DM fallback when `fallback_to_dm: true`."
  @spec post_ephemeral(String.t() | integer(), String.t() | integer(), String.t(), keyword()) ::
          {:ok, Jido.Chat.EphemeralMessage.t()} | {:error, term()}
  defdelegate post_ephemeral(chat_id, user_id, text, opts), to: Adapter

  @doc "Adds reaction to a Telegram message when supported by bot permissions."
  @spec add_reaction(String.t() | integer(), String.t() | integer(), String.t(), keyword()) ::
          :ok | {:error, term()}
  defdelegate add_reaction(chat_id, message_id, emoji, opts), to: Adapter

  @doc "Removes reaction from a Telegram message when supported by bot permissions."
  @spec remove_reaction(String.t() | integer(), String.t() | integer(), String.t(), keyword()) ::
          :ok | {:error, term()}
  defdelegate remove_reaction(chat_id, message_id, emoji, opts), to: Adapter

  @doc "Thread/channel history is unsupported by Telegram adapter in Phase 2."
  @spec fetch_messages(String.t() | integer(), keyword()) ::
          {:ok, Jido.Chat.MessagePage.t()} | {:error, term()}
  defdelegate fetch_messages(chat_id, opts), to: Adapter

  @doc "Channel-level history is unsupported by Telegram adapter in Phase 2."
  @spec fetch_channel_messages(String.t() | integer(), keyword()) ::
          {:ok, Jido.Chat.MessagePage.t()} | {:error, term()}
  defdelegate fetch_channel_messages(chat_id, opts), to: Adapter

  @doc "Thread listing is unsupported by Telegram adapter in Phase 2."
  @spec list_threads(String.t() | integer(), keyword()) ::
          {:ok, Jido.Chat.ThreadPage.t()} | {:error, term()}
  defdelegate list_threads(chat_id, opts), to: Adapter

  @doc "Adapter webhook helper."
  @spec handle_webhook(Jido.Chat.t(), map(), keyword()) ::
          {:ok, Jido.Chat.t(), Jido.Chat.Incoming.t()} | {:error, term()}
  defdelegate handle_webhook(chat, payload, opts), to: Adapter
end
