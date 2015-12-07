require "test_helper"
require "resilient/circuit_breaker"

module Resilient
  class CircuitBreakerTest < Minitest::Test
    def setup
      @object = CircuitBreaker.new
    end

    include CircuitBreakerInterfaceTest

    def test_allow_request_when_under_error_threshold_percentage
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 51,
        request_volume_threshold: 0,
      })
      metrics = CircuitBreaker::RollingMetrics.new
      metrics.mark_success
      metrics.mark_failure
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)

      assert circuit_breaker.allow_request?
    end

    def test_allow_request_when_over_error_threshold_percentage
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 49,
        request_volume_threshold: 0,
      })
      metrics = CircuitBreaker::RollingMetrics.new
      metrics.mark_success
      metrics.mark_failure
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)

      refute circuit_breaker.allow_request?
    end

    def test_allow_request_when_at_error_threshold_percentage
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 50,
        request_volume_threshold: 0,
      })
      metrics = CircuitBreaker::RollingMetrics.new
      metrics.mark_success
      metrics.mark_failure
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)

      refute circuit_breaker.allow_request?
    end

    def test_allow_request_when_under_request_volume_threshold
      config = CircuitBreaker::Config.new(request_volume_threshold: 5)
      metrics = CircuitBreaker::RollingMetrics.new
      4.times { metrics.mark_failure }
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)

      assert circuit_breaker.allow_request?
    end

    def test_allow_request_with_circuit_open_but_after_sleep_window_seconds
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 49,
        request_volume_threshold: 0,
        sleep_window_seconds: 5,
      })
      metrics = CircuitBreaker::RollingMetrics.new
      metrics.mark_success
      metrics.mark_failure
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)

      refute circuit_breaker.allow_request?

      Timecop.freeze(Time.now + 4) do
        refute circuit_breaker.allow_request?
      end

      Timecop.freeze(Time.now + 5) do
        refute circuit_breaker.allow_request?
      end

      Timecop.freeze(Time.now + 6) do
        assert circuit_breaker.allow_request?
      end
    end

    def test_allow_request_when_forced_open_but_under_threshold
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 51,
        request_volume_threshold: 0,
        force_open: true,
      })
      metrics = CircuitBreaker::RollingMetrics.new
      metrics.mark_success
      metrics.mark_failure
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)

      refute circuit_breaker.allow_request?
    end

    def test_allow_request_when_forced_closed_but_over_threshold
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 49,
        request_volume_threshold: 0,
        force_closed: true,
      })
      metrics = CircuitBreaker::RollingMetrics.new
      metrics.mark_success
      metrics.mark_failure
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)

      assert circuit_breaker.allow_request?
    end

    def test_mark_success
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 49,
        request_volume_threshold: 0,
      })
      metrics = CircuitBreaker::RollingMetrics.new
      metrics.mark_success
      metrics.mark_failure
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)

      refute circuit_breaker.allow_request?
      circuit_breaker.mark_success
      assert circuit_breaker.allow_request?
    end

    def test_mark_failure
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 49,
        request_volume_threshold: 0,
      })
      metrics = CircuitBreaker::RollingMetrics.new
      metrics.mark_success
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)

      assert circuit_breaker.allow_request?
      assert_equal 0, metrics.failures
      circuit_breaker.mark_failure
      refute circuit_breaker.allow_request?
      assert_equal 1, metrics.failures
    end

    def test_reset_calls_reset_on_metrics
      metrics = Minitest::Mock.new
      circuit_breaker = CircuitBreaker.new(metrics: metrics)

      metrics.expect :reset, nil
      circuit_breaker.reset
      metrics.verify
    end

    def test_reset_sets_open_to_false
      circuit_breaker = CircuitBreaker.new
      circuit_breaker.reset
      assert_equal false, circuit_breaker.instance_variable_get("@open")
    end

    def test_reset_sets_opened_at_to_zero
      circuit_breaker = CircuitBreaker.new
      circuit_breaker.reset
      assert_equal 0, circuit_breaker.instance_variable_get("@opened_at")
    end
  end
end
