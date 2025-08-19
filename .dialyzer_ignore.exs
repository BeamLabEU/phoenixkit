[
  # Mix functions are only available during compilation, not at runtime
  {"lib/mix/tasks/phoenix_kit.gen.migration.ex", :unknown_function},
  {"lib/mix/tasks/phoenix_kit.install.ex", :unknown_function},
  {"lib/mix/tasks/phoenix_kit.update.ex", :unknown_function},
  {"lib/phoenix_kit/migrations/postgres.ex", :unknown_function},
  {"lib/phoenix_kit_web/users/auth.ex", :unknown_function},

  # Mix.Task behaviour callbacks are expected in Mix tasks
  {"lib/mix/tasks/phoenix_kit.gen.migration.ex", :callback_info_missing},
  {"lib/mix/tasks/phoenix_kit.install.ex", :callback_info_missing},
  {"lib/mix/tasks/phoenix_kit.update.ex", :callback_info_missing},

  # Ecto.Multi opaque type warnings - false positives, code works correctly
  ~r/lib\/phoenix_kit\/users\/auth\.ex:212:.*call_without_opaque/,
  ~r/lib\/phoenix_kit\/users\/auth\.ex:265:.*call_without_opaque/,
  ~r/lib\/phoenix_kit\/users\/auth\.ex:344:.*call_without_opaque/,
  ~r/lib\/phoenix_kit\/users\/auth\.ex:401:.*call_without_opaque/,

  # PhoenixModuleTemplate is a demo module not meant to be called at runtime
  {"lib/phoenix_module_template.ex", :no_return},
  {"lib/phoenix_module_template/context.ex", :no_return},
  {"lib/phoenix_module_template/context.ex", :call},
  {"lib/phoenix_module_template/schema/example.ex", :no_return},
  {"lib/phoenix_module_template/schema/example.ex", :call}
]
