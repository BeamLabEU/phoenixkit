defmodule PhoenixKit.Repo.Migrations.AddPhoenixKitAuthTables do
  use Ecto.Migration

  def up, do: PhoenixKit.Migration.up(create_schema: true, prefix: "auth")

  def down, do: PhoenixKit.Migration.down(create_schema: true, prefix: "auth")
end
