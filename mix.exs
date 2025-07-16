defmodule PhonixKit.MixProject do
  use Mix.Project

  def project do
    [
      app: :phonix_kit,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix_live_view, "~> 0.18"}
    ]
  end

  defp description do
    "Минимальный Phoenix компонент для welcome страниц"
  end

  defp package do
    [
      name: "phonix_kit",
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Anonymous"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/example/phonix_kit"}
    ]
  end
end