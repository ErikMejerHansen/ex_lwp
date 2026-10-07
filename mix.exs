defmodule ExLWP.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/ErikMejerHansen/ex_lwp"

  def project do
    [
      app: :ex_lwp,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: description(),
      package: package(),
      name: "ExLWP",
      source_url: @source_url,
      docs: docs()
    ]
  end

  def cli do
    [preferred_envs: [spec: :test]]
  end

  def application do
    [extra_applications: []]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      # Runs the tests and writes spec/STATUS.md
      spec: ["test --formatter ExUnit.CLIFormatter --formatter ExLWP.SpecFormatter"]
    ]
  end

  defp description do
    "Stateless encoder/decoder for the LEGO® Wireless Protocol 3.0 (Powered Up hubs). " <>
      "Not affiliated with, sponsored or endorsed by The LEGO Group."
  end

  defp package do
    [
      name: "ex_lwp",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "LEGO Wireless Protocol docs" => "https://lego.github.io/lego-ble-wireless-protocol-docs/"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: ["README.md", "notebooks/powered_up.livemd"],
      groups_for_modules: [
        Codec: [ExLWP, ExLWP.Message, ExLWP.Output, ExLWP.Messages],
        "Wire format": [
          ExLWP.Header,
          ExLWP.Enums,
          ExLWP.Version,
          ExLWP.ValueFormat,
          ExLWP.Advertisement
        ],
        Messages: ~r/^ExLWP\.Message\./,
        "Output sub commands": ~r/^ExLWP\.Output\./
      ]
    ]
  end
end
