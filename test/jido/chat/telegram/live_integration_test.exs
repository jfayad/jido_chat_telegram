defmodule Jido.Chat.Telegram.LiveIntegrationTest do
  use ExUnit.Case, async: false

  alias Jido.Chat
  alias Jido.Chat.Telegram.Adapter
  alias Jido.Chat.Telegram.Extensions

  @run_live System.get_env("RUN_LIVE_TELEGRAM_TESTS") in ["1", "true", "TRUE", "yes", "on"]
  @token System.get_env("TELEGRAM_BOT_TOKEN")
  @chat_id System.get_env("TELEGRAM_TEST_CHAT_ID")
  @callback_query_id System.get_env("TELEGRAM_TEST_CALLBACK_QUERY_ID")
  @photo_ref System.get_env("TELEGRAM_TEST_PHOTO_REF")
  @document_ref System.get_env("TELEGRAM_TEST_DOCUMENT_REF")

  @moduletag :live

  if not @run_live do
    @moduletag skip: "set RUN_LIVE_TELEGRAM_TESTS=true to run live Telegram integration tests"
  end

  if @run_live and (is_nil(@token) or @token == "" or is_nil(@chat_id) or @chat_id == "") do
    @moduletag skip:
                 "set TELEGRAM_BOT_TOKEN and TELEGRAM_TEST_CHAT_ID when RUN_LIVE_TELEGRAM_TESTS=true"
  end

  setup_all do
    {:ok, token: @token, chat_id: @chat_id, opts: adapter_opts(@token)}
  end

  test "send/edit/delete message against live Telegram Bot API", ctx do
    text = "jido live integration #{System.system_time(:millisecond)}"

    assert {:ok, sent} = Adapter.send_message(ctx.chat_id, text, ctx.opts)
    message_id = sent.message_id || sent.external_message_id
    assert message_id

    assert {:ok, edited} =
             Adapter.edit_message(ctx.chat_id, message_id, text <> " (edited)", ctx.opts)

    assert (edited.message_id || edited.external_message_id) == message_id
    assert :ok = Adapter.delete_message(ctx.chat_id, message_id, ctx.opts)
  end

  test "typing and metadata calls succeed against live Telegram API", ctx do
    assert :ok = Adapter.start_typing(ctx.chat_id, ctx.opts)

    assert {:ok, info} = Adapter.fetch_metadata(ctx.chat_id, ctx.opts)
    assert info.id == to_string(ctx.chat_id)
  end

  test "stream sends draft updates and a final message against live Telegram Bot API", ctx do
    chunk_stream =
      Stream.concat([
        ["streaming"],
        Stream.map([" response"], fn chunk ->
          Process.sleep(300)
          chunk
        end)
      ])

    assert {:ok, sent} =
             Adapter.stream(
               ctx.chat_id,
               chunk_stream,
               Keyword.merge(ctx.opts,
                 draft_id: System.unique_integer([:positive]),
                 stream_update_interval_ms: 250
               )
             )

    message_id = sent.message_id || sent.external_message_id
    assert message_id

    assert :ok = Adapter.delete_message(ctx.chat_id, message_id, ctx.opts)
  end

  test "webhook handling pipeline processes Telegram-shaped payload", ctx do
    chat =
      Chat.new(user_name: "jido", adapters: %{telegram: Adapter})
      |> Chat.on_slash_command(fn _event -> send(self(), :slash_seen) end)

    payload = %{
      "message" => %{
        "message_id" => 9_999_001,
        "chat" => %{"id" => ctx.chat_id, "type" => "private"},
        "from" => %{"id" => 9_999_002, "username" => "live_user"},
        "text" => "/help integration"
      }
    }

    assert {:ok, _chat, _incoming} = Adapter.handle_webhook(chat, payload, ctx.opts)
    assert_received :slash_seen
  end

  test "extension media sends succeed against live Telegram Bot API", ctx do
    photo_ref = @photo_ref || "https://httpbin.org/image/png"

    document_ref =
      @document_ref || "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"

    assert {:ok, photo} =
             Extensions.send_photo(ctx.chat_id, photo_ref,
               token: ctx.token,
               caption: "jido live photo #{System.system_time(:millisecond)}"
             )

    assert photo.kind == :photo
    assert to_string(photo.chat_id) == to_string(ctx.chat_id)

    assert {:ok, document} =
             Extensions.send_document(ctx.chat_id, document_ref,
               token: ctx.token,
               caption: "jido live document #{System.system_time(:millisecond)}"
             )

    assert document.kind == :document
    assert to_string(document.chat_id) == to_string(ctx.chat_id)
  end

  test "webhook handling supports channel_post and edited_channel_post shapes", ctx do
    chat = Chat.new(user_name: "jido", adapters: %{telegram: Adapter})

    channel_post = %{
      "channel_post" => %{
        "message_id" => 9_999_011,
        "chat" => %{"id" => ctx.chat_id, "type" => "channel", "title" => "live"},
        "from" => %{"id" => 9_999_012, "username" => "live_user"},
        "text" => "live channel post"
      }
    }

    edited_channel_post = %{
      "edited_channel_post" => %{
        "message_id" => 9_999_013,
        "chat" => %{"id" => ctx.chat_id, "type" => "channel", "title" => "live"},
        "from" => %{"id" => 9_999_014, "username" => "live_user"},
        "text" => "live edited channel post"
      }
    }

    assert {:ok, _chat, incoming_1} = Adapter.handle_webhook(chat, channel_post, ctx.opts)
    assert incoming_1.external_message_id == 9_999_011

    assert {:ok, _chat, incoming_2} = Adapter.handle_webhook(chat, edited_channel_post, ctx.opts)
    assert incoming_2.external_message_id == 9_999_013
  end

  test "unsupported core surfaces remain explicit unsupported contracts", ctx do
    assert {:error, :unsupported} = Adapter.fetch_messages(ctx.chat_id, ctx.opts)
    assert {:error, :unsupported} = Adapter.fetch_channel_messages(ctx.chat_id, ctx.opts)
    assert {:error, :unsupported} = Adapter.list_threads(ctx.chat_id, ctx.opts)

    assert {:error, :unsupported} =
             Jido.Chat.Adapter.open_modal(Adapter, ctx.chat_id, %{title: "modal"}, ctx.opts)
  end

  if @callback_query_id not in [nil, ""] do
    test "manual callback query answer succeeds when TELEGRAM_TEST_CALLBACK_QUERY_ID is provided",
         ctx do
      case Extensions.answer_callback_query(@callback_query_id,
             token: ctx.token,
             text: "ack from live integration test",
             show_alert: false
           ) do
        {:ok, result} ->
          assert result.answered == true
          assert result.callback_query_id == @callback_query_id

        {:error, error} ->
          message = Exception.message(error)

          assert message =~ "query is too old" or
                   message =~ "query ID is invalid"
      end
    end
  else
    test "manual callback query answer requires TELEGRAM_TEST_CALLBACK_QUERY_ID" do
      assert is_nil(@callback_query_id) or @callback_query_id == ""
    end
  end

  defp adapter_opts(token) do
    opts = [token: token]

    case parse_optional_int(System.get_env("TELEGRAM_TEST_THREAD_ID")) do
      nil -> opts
      thread_id -> Keyword.put(opts, :thread_id, thread_id)
    end
  end

  defp parse_optional_int(nil), do: nil
  defp parse_optional_int(""), do: nil

  defp parse_optional_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> value
    end
  end
end
