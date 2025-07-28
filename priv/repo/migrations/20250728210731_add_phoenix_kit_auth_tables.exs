defmodule PhoenixKit.Repo.Migrations.AddPhoenixKitAuthTables do
  use Ecto.Migration

def up, do: PhoenixKit.Migration.up()

def down, do: PhoenixKit.Migration.down()

end
