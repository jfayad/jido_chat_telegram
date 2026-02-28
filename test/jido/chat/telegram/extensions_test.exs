defmodule Jido.Chat.Telegram.ExtensionsTest do
  use ExUnit.Case, async: true

  alias Jido.Chat.Telegram.{
    CallbackQuery,
    Extensions,
    InlineKeyboard,
    MediaMessage,
    UpdateEnvelope
  }

  defmodule MockTransport do
    @behaviour Jido.Chat.Telegram.Transport

    @impl true
    def call(_token, "sendPhoto", payload, _opts) do
      {:ok,
       %{
         "message_id" => 200,
         "chat" => %{"id" => payload["chat_id"]},
         "caption" => payload["caption"],
         "photo" => [%{"file_id" => "photo-file-id"}]
       }}
    end

    @impl true
    def call(_token, "sendDocument", payload, _opts) do
      {:ok,
       %{
         "message_id" => 201,
         "chat" => %{"id" => payload["chat_id"]},
         "caption" => payload["caption"],
         "document" => %{"file_id" => "doc-file-id"}
       }}
    end

    @impl true
    def call(_token, "answerCallbackQuery", payload, _opts) do
      {:ok, %{"ok" => true, "callback_query_id" => payload["callback_query_id"]}}
    end
  end

  test "capabilities/0 exposes extension-specific surface" do
    caps = Extensions.capabilities()
    assert caps.send_photo == :native
    assert caps.answer_callback_query == :native
    assert caps.send_media_group == :unsupported
  end

  test "parse_update/1 normalizes callback_query into typed envelope" do
    update = %{
      "update_id" => 10,
      "callback_query" => %{
        "id" => "cb-1",
        "data" => "approve",
        "from" => %{"id" => 50, "username" => "bob"},
        "message" => %{
          "message_id" => 100,
          "chat" => %{"id" => 123, "type" => "private"}
        }
      }
    }

    assert {:ok, %UpdateEnvelope{} = envelope} = Extensions.parse_update(update)
    assert envelope.update_type == :callback_query

    assert %CallbackQuery{id: "cb-1", data: "approve", chat_id: 123, message_id: 100} =
             envelope.payload
  end

  test "parse_update/1 returns noop envelope for unsupported updates" do
    assert {:ok, %UpdateEnvelope{update_type: :noop}} =
             Extensions.parse_update(%{"update_id" => 11, "poll" => %{}})
  end

  test "send_photo/send_document return typed media messages" do
    assert {:ok, %MediaMessage{} = photo} =
             Extensions.send_photo(123, "photo-id",
               token: "bot-token",
               transport: MockTransport,
               caption: "hello"
             )

    assert photo.kind == :photo
    assert photo.chat_id == 123
    assert photo.file_id == "photo-file-id"

    assert {:ok, %MediaMessage{} = doc} =
             Extensions.send_document(123, "doc-id",
               token: "bot-token",
               transport: MockTransport,
               caption: "readme"
             )

    assert doc.kind == :document
    assert doc.file_id == "doc-file-id"
  end

  test "answer_callback_query/2 returns typed callback answer result" do
    assert {:ok, result} =
             Extensions.answer_callback_query("cb-2",
               token: "bot-token",
               transport: MockTransport,
               text: "done"
             )

    assert result.answered == true
    assert result.callback_query_id == "cb-2"
  end

  test "InlineKeyboard.to_reply_markup/1 builds telegram wire shape" do
    keyboard =
      InlineKeyboard.new(%{
        rows: [
          [
            %{text: "Approve", callback_data: "approve"},
            %{text: "Docs", url: "https://example.com"}
          ]
        ]
      })

    assert %{
             "inline_keyboard" => [
               [
                 %{"text" => "Approve", "callback_data" => "approve"},
                 %{"text" => "Docs", "url" => "https://example.com"}
               ]
             ]
           } = InlineKeyboard.to_reply_markup(keyboard)
  end
end
