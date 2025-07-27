defmodule PhoenixKit.Repo.Migrations.CreatePhoenixKitAuthTables do
  use Ecto.Migration

  def up, do: PhoenixKit.Migration.up()

  def down, do: PhoenixKit.Migration.down()
end
