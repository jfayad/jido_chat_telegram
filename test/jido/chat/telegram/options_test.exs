defmodule Jido.Chat.Telegram.OptionsTest do
  use ExUnit.Case, async: true

  alias Jido.Chat.Telegram.{
    DeleteOptions,
    EditOptions,
    MetadataOptions,
    ReactionOptions,
    SendOptions,
    TypingOptions
  }

  test "SendOptions.new/1 normalizes keyword options into typed struct" do
    options =
      SendOptions.new(
        token: "token",
        parse_mode: "HTML",
        reply_to_message_id: 123,
        thread_id: 456,
        debug: true
      )

    assert options.token == "token"
    assert options.parse_mode == "HTML"
    assert options.reply_to_message_id == 123
    assert options.thread_id == 456

    assert %{
             "parse_mode" => "HTML",
             "reply_to_message_id" => 123,
             "message_thread_id" => 456
           } = SendOptions.payload_opts(options)

    assert [debug: true] = SendOptions.transport_opts(options)
  end

  test "EditOptions.new/1 normalizes keyword options into typed struct" do
    options =
      EditOptions.new(
        token: "token",
        parse_mode: "MarkdownV2",
        disable_web_page_preview: true
      )

    assert options.token == "token"
    assert options.parse_mode == "MarkdownV2"

    assert %{
             "parse_mode" => "MarkdownV2",
             "disable_web_page_preview" => true
           } = EditOptions.payload_opts(options)
  end

  test "TypingOptions.new/1 includes action and thread payload" do
    options = TypingOptions.new(token: "token", action: "upload_photo", thread_id: 999)

    assert options.action == "upload_photo"
    assert options.thread_id == 999

    assert %{"action" => "upload_photo", "message_thread_id" => 999} =
             TypingOptions.payload_opts(options)
  end

  test "DeleteOptions and MetadataOptions normalize transport options" do
    delete_opts = DeleteOptions.new(token: "token", debug: true)
    metadata_opts = MetadataOptions.new(token: "token", check_params: false)

    assert delete_opts.token == "token"
    assert metadata_opts.token == "token"

    assert [debug: true] = DeleteOptions.transport_opts(delete_opts)
    assert [check_params: false] = MetadataOptions.transport_opts(metadata_opts)
  end

  test "ReactionOptions normalizes payload and transport options" do
    options = ReactionOptions.new(token: "token", is_big: true, debug: true)

    assert options.token == "token"
    assert options.is_big == true
    assert %{"is_big" => true} = ReactionOptions.payload_opts(options)
    assert [debug: true] = ReactionOptions.transport_opts(options)
  end
end
