defmodule PhoenixKit.Install.PerformanceBenchmarker do
  @moduledoc """
  Модуль для измерения производительности новых оптимизированных модулей PhoenixKit.

  Этот модуль:
  - Измеряет время выполнения ключевых операций
  - Сравнивает производительность до и после оптимизаций
  - Предоставляет метрики для мониторинга производительности
  - Помогает идентифицировать узкие места в производительности
  """

  require Logger

  @benchmark_operations %{
    router_analysis: %{
      description: "Router analysis and AST parsing",
      module: PhoenixKit.Install.RouterIntegration.ASTAnalyzer,
      function: :find_and_analyze_router,
      expected_time_ms: 500
    },
    layout_detection: %{
      description: "Layout file discovery and analysis",
      module: PhoenixKit.Install.LayoutIntegration.LayoutDetector,
      function: :detect_existing_layouts,
      expected_time_ms: 1000
    },
    dependency_analysis: %{
      description: "Dependency conflict analysis",
      module: PhoenixKit.Install.ConflictDetection.DependencyAnalyzer,
      function: :analyze_auth_dependencies,
      expected_time_ms: 300
    },
    layout_enhancement: %{
      description: "Layout enhancement and optimization",
      module: PhoenixKit.Install.LayoutIntegration.LayoutEnhancer,
      function: :enhance_layouts,
      expected_time_ms: 2000
    }
  }

  @doc """
  Запускает полный набор бенчмарков для всех оптимизированных модулей.

  ## Returns

  - `{:ok, benchmark_results}` - результаты бенчмарков
  - `{:error, reason}` - ошибка при выполнении бенчмарков

  ## Examples

      iex> PerformanceBenchmarker.run_full_benchmark(igniter)
      {:ok, %{
        total_duration_ms: 1500,
        operations: [...],
        performance_score: 85,
        recommendations: [...]
      }}
  """
  def run_full_benchmark(igniter) do
    Logger.info("🏁 Starting PhoenixKit performance benchmark")

    benchmark_start_time = System.monotonic_time(:millisecond)

    with {:ok, operation_results} <- run_operation_benchmarks(igniter),
         {:ok, memory_metrics} <- measure_memory_usage(igniter),
         {:ok, cache_metrics} <- measure_cache_effectiveness() do
      benchmark_duration = System.monotonic_time(:millisecond) - benchmark_start_time

      benchmark_results = %{
        benchmark_timestamp: DateTime.utc_now(),
        total_duration_ms: benchmark_duration,
        operation_results: operation_results,
        memory_metrics: memory_metrics,
        cache_metrics: cache_metrics,
        performance_score: calculate_performance_score(operation_results),
        recommendations: generate_performance_recommendations(operation_results, memory_metrics),
        system_info: collect_system_info()
      }

      log_benchmark_summary(benchmark_results)
      {:ok, benchmark_results}
    else
      error ->
        Logger.error("❌ Benchmark failed: #{inspect(error)}")
        error
    end
  end

  @doc """
  Измеряет производительность конкретной операции.
  """
  def benchmark_operation(operation_name, igniter, opts \\ []) do
    case Map.get(@benchmark_operations, operation_name) do
      nil ->
        {:error, {:unknown_operation, operation_name}}

      operation_config ->
        run_single_benchmark(operation_config, igniter, opts)
    end
  end

  @doc """
  Сравнивает производительность с базовыми показателями.
  """
  def compare_with_baseline(benchmark_results, baseline_results \\ nil) do
    baseline = baseline_results || get_default_baseline()

    comparisons =
      benchmark_results.operation_results
      |> Enum.map(fn {operation, result} ->
        baseline_time = get_baseline_time(baseline, operation)
        improvement = calculate_improvement(result.duration_ms, baseline_time)

        %{
          operation: operation,
          current_time_ms: result.duration_ms,
          baseline_time_ms: baseline_time,
          improvement_percent: improvement,
          status: determine_performance_status(improvement)
        }
      end)

    %{
      overall_improvement: calculate_overall_improvement(comparisons),
      operation_comparisons: comparisons,
      performance_trend: determine_performance_trend(comparisons)
    }
  end

  # ============================================================================
  # Private Helper Functions
  # ============================================================================

  defp run_operation_benchmarks(igniter) do
    Logger.debug("Running operation benchmarks...")

    operation_results =
      @benchmark_operations
      |> Enum.map(fn {operation_name, operation_config} ->
        case run_single_benchmark(operation_config, igniter) do
          {:ok, result} ->
            {operation_name, result}

          {:error, reason} ->
            Logger.warning("Failed to benchmark #{operation_name}: #{inspect(reason)}")
            {operation_name, %{error: reason, duration_ms: :timeout}}
        end
      end)
      |> Enum.into(%{})

    {:ok, operation_results}
  end

  defp run_single_benchmark(operation_config, igniter, opts \\ []) do
    _timeout = Keyword.get(opts, :timeout, 10_000)
    iterations = Keyword.get(opts, :iterations, 1)

    Logger.debug("Benchmarking #{operation_config.description}...")

    try do
      # Измеряем время выполнения
      start_time = System.monotonic_time(:millisecond)

      results =
        Enum.map(1..iterations, fn _iteration ->
          case apply(operation_config.module, operation_config.function, [igniter]) do
            {:ok, _result} -> :success
            {:error, reason} -> {:error, reason}
          end
        end)

      end_time = System.monotonic_time(:millisecond)
      total_duration = end_time - start_time
      avg_duration = div(total_duration, iterations)

      # Анализируем результаты
      successful_runs = Enum.count(results, &(&1 == :success))
      success_rate = successful_runs / iterations * 100

      benchmark_result = %{
        operation: operation_config.description,
        duration_ms: avg_duration,
        total_duration_ms: total_duration,
        iterations: iterations,
        success_rate: success_rate,
        expected_time_ms: operation_config.expected_time_ms,
        performance_ratio: avg_duration / operation_config.expected_time_ms,
        status: determine_benchmark_status(avg_duration, operation_config.expected_time_ms)
      }

      {:ok, benchmark_result}
    rescue
      error ->
        {:error, {:benchmark_error, error}}
    catch
      :exit, reason ->
        {:error, {:benchmark_timeout, reason}}
    after
      # Очищаем память после бенчмарка
      :erlang.garbage_collect()
    end
  end

  defp measure_memory_usage(_igniter) do
    Logger.debug("Measuring memory usage...")

    # Получаем метрики памяти
    memory_info = :erlang.memory()

    memory_metrics = %{
      total_memory: memory_info[:total],
      process_memory: memory_info[:processes],
      ets_memory: memory_info[:ets],
      binary_memory: memory_info[:binary],
      memory_efficiency_score: calculate_memory_efficiency_score(memory_info)
    }

    {:ok, memory_metrics}
  end

  defp measure_cache_effectiveness do
    Logger.debug("Measuring cache effectiveness...")

    # Измеряем эффективность кэшей
    cache_metrics = %{
      router_cache_hits: get_cache_hits(:phoenix_kit_analysis_cache),
      layout_cache_hits: get_cache_hits(:phoenix_kit_layout_cache),
      cache_effectiveness_score: calculate_cache_effectiveness_score()
    }

    {:ok, cache_metrics}
  end

  defp calculate_performance_score(operation_results) do
    scores =
      operation_results
      |> Enum.map(fn {_operation, result} ->
        case result do
          %{performance_ratio: ratio} when is_number(ratio) ->
            # Лучше, если время выполнения меньше ожидаемого (ratio < 1.0)
            max(0, 100 - (ratio - 1.0) * 50)

          _ ->
            # Средний балл для неуспешных операций
            50
        end
      end)

    if length(scores) > 0 do
      (Enum.sum(scores) / length(scores)) |> round()
    else
      0
    end
  end

  defp generate_performance_recommendations(operation_results, memory_metrics) do
    recommendations = ["Performance benchmark completed"]

    # Рекомендации по операциям
    slow_operations =
      operation_results
      |> Enum.filter(fn {_operation, result} ->
        case result do
          %{performance_ratio: ratio} -> ratio > 1.5
          _ -> false
        end
      end)

    recommendations =
      recommendations ++
        if length(slow_operations) > 0 do
          ["⚠️  Some operations are slower than expected - consider optimization"]
        else
          ["✅ All operations performing within expected parameters"]
        end

    # Рекомендации по памяти
    recommendations =
      recommendations ++
        if memory_metrics.memory_efficiency_score < 70 do
          [
            "🧠 Consider memory optimization - efficiency score: #{memory_metrics.memory_efficiency_score}%"
          ]
        else
          ["✅ Memory usage is efficient"]
        end

    recommendations
  end

  defp collect_system_info do
    %{
      elixir_version: System.version(),
      otp_version: System.otp_release(),
      schedulers: System.schedulers_online(),
      memory_total: :erlang.memory(:total),
      architecture: to_string(:erlang.system_info(:system_architecture))
    }
  end

  defp determine_benchmark_status(actual_time, expected_time) do
    ratio = actual_time / expected_time

    cond do
      ratio <= 0.8 -> :excellent
      ratio <= 1.0 -> :good
      ratio <= 1.5 -> :acceptable
      true -> :slow
    end
  end

  defp get_default_baseline do
    # Базовые показатели для сравнения
    %{
      # 600ms
      router_analysis: 600,
      # 1200ms
      layout_detection: 1200,
      # 400ms
      dependency_analysis: 400,
      # 2500ms
      layout_enhancement: 2500
    }
  end

  defp get_baseline_time(baseline, operation) do
    Map.get(baseline, operation, 1000)
  end

  defp calculate_improvement(current_time, baseline_time) do
    ((baseline_time - current_time) / baseline_time * 100) |> round()
  end

  defp determine_performance_status(improvement) do
    cond do
      improvement >= 20 -> :significantly_improved
      improvement >= 10 -> :improved
      improvement >= -10 -> :stable
      true -> :degraded
    end
  end

  defp calculate_overall_improvement(comparisons) do
    improvements = Enum.map(comparisons, & &1.improvement_percent)

    if length(improvements) > 0 do
      (Enum.sum(improvements) / length(improvements)) |> round()
    else
      0
    end
  end

  defp determine_performance_trend(comparisons) do
    improved_count = Enum.count(comparisons, &(&1.improvement_percent > 0))
    total_count = length(comparisons)

    cond do
      improved_count >= total_count * 0.8 -> :improving
      improved_count >= total_count * 0.5 -> :mixed
      true -> :declining
    end
  end

  defp calculate_memory_efficiency_score(memory_info) do
    # Простая оценка эффективности памяти
    total = memory_info[:total]
    used = memory_info[:processes] + memory_info[:ets]

    if total > 0 do
      efficiency = (1 - used / total) * 100
      max(0, min(100, efficiency)) |> round()
    else
      50
    end
  end

  defp get_cache_hits(cache_name) do
    try do
      case :ets.info(cache_name, :size) do
        :undefined -> 0
        size when is_integer(size) -> size
        _ -> 0
      end
    rescue
      _ -> 0
    end
  end

  defp calculate_cache_effectiveness_score do
    # Простая оценка эффективности кэша
    router_hits = get_cache_hits(:phoenix_kit_analysis_cache)
    layout_hits = get_cache_hits(:phoenix_kit_layout_cache)

    total_hits = router_hits + layout_hits

    cond do
      total_hits >= 10 -> 90
      total_hits >= 5 -> 70
      total_hits >= 1 -> 50
      true -> 30
    end
  end

  defp log_benchmark_summary(results) do
    Logger.info("🏆 Performance Benchmark Summary:")
    Logger.info("   Duration: #{results.total_duration_ms}ms")
    Logger.info("   Performance score: #{results.performance_score}/100")
    Logger.info("   Memory efficiency: #{results.memory_metrics.memory_efficiency_score}%")
    Logger.info("   Cache effectiveness: #{results.cache_metrics.cache_effectiveness_score}%")
    Logger.info("   Operations benchmarked: #{map_size(results.operation_results)}")

    # Показываем топ медленных операций
    slow_operations =
      results.operation_results
      |> Enum.filter(fn {_op, result} ->
        case result do
          %{status: status} -> status in [:slow, :acceptable]
          _ -> false
        end
      end)

    if length(slow_operations) > 0 do
      Logger.warning("⚠️  Slow operations detected:")

      Enum.each(slow_operations, fn {operation, result} ->
        Logger.warning(
          "   #{operation}: #{result.duration_ms}ms (expected: #{result.expected_time_ms}ms)"
        )
      end)
    end
  end
end
