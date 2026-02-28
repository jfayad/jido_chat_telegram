defmodule Jido.Chat.TelegramTest do
  use ExUnit.Case, async: true

  test "channel/0 returns the telegram channel module" do
    assert Jido.Chat.Telegram.channel() == Jido.Chat.Telegram.Channel
  end
end
