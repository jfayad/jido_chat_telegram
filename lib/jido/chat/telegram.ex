defmodule Jido.Chat.Telegram do
  @moduledoc """
  Telegram adapter package for `Jido.Chat`.

  This package avoids Telegex and uses ExGram as the Telegram client.
  """

  alias Jido.Chat.Telegram.Adapter
  alias Jido.Chat.Telegram.Channel

  @spec adapter() :: module()
  def adapter, do: Adapter

  @spec channel() :: module()
  def channel, do: Channel
end
