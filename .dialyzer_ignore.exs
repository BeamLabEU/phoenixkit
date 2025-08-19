[
  # Mix functions are only available during Mix compilation context
  {"lib/mix/tasks/phoenix_kit.install.ex", :unknown_function},
  {"lib/mix/tasks/phoenix_kit.update.ex", :unknown_function},

  # Mix.Task behaviour callbacks (expected in Mix tasks)
  {"lib/mix/tasks/phoenix_kit.gen.migration.ex", :callback_info_missing, 1},
  {"lib/mix/tasks/phoenix_kit.install.ex", :callback_info_missing, 1},
  {"lib/mix/tasks/phoenix_kit.update.ex", :callback_info_missing, 1},

  # Ecto.Multi opaque type false positives (code works correctly)
  ~r/lib\/phoenix_kit\/users\/auth\.ex:.*call_without_opaque/
]
