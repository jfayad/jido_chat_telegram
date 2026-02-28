defmodule Jido.Chat.Telegram.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/agentjido/jido_chat_telegram"

  def project do
    [
      app: :jido_chat_telegram,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      name: "Jido Chat Telegram",
      description: "Telegram adapter package for Jido.Chat",
      source_url: @source_url,
      homepage_url: @source_url
    ]
  end

  def cli do
    [preferred_envs: [quality: :test, q: :test]]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jido_chat, github: "agentjido/jido_chat", branch: "main"},
      {:ex_gram, "~> 0.57"},
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:dotenvy, "~> 1.1", only: [:test]}
    ]
  end

  defp aliases do
    [
      q: ["quality"],
      quality: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "test"
      ]
    ]
  end
end
