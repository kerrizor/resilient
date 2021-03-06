require "test_helper"
require "resilient/circuit_breaker/properties"
require "resilient/instrumenters/noop"
require "resilient/instrumenters/memory"
require "resilient/test/properties_interface"

module Resilient
  class CircuitBreaker
    class PropertiesTest < Test
      def setup
        super
        @object = Properties.new
      end

      include Test::PropertiesInterface

      def test_defaults_force_open
        assert_equal false, @object.force_open
      end

      def test_allows_overriding_force_open
        assert_equal true, Properties.new(force_open: true).force_open
      end

      def test_defaults_force_closed
        assert_equal false, @object.force_closed
      end

      def test_allows_overriding_force_closed
        assert_equal true, Properties.new(force_closed: true).force_closed
      end

      def test_defaults_instrumenter
        assert_equal Instrumenters::Noop, @object.instrumenter
      end

      def test_allows_overriding_instrumenter
        instrumenter = Instrumenters::Memory.new
        assert_equal instrumenter, Properties.new(instrumenter: instrumenter).instrumenter
      end

      def test_defaults_sleep_window_seconds
        assert_equal 5, @object.sleep_window_seconds
      end

      def test_allows_overriding_sleep_window_seconds
        assert_equal 2, Properties.new(sleep_window_seconds: 2).sleep_window_seconds
      end

      def test_defaults_request_volume_threshold
        assert_equal 20, @object.request_volume_threshold
      end

      def test_allows_overriding_request_volume_threshold
        assert_equal 1, Properties.new(request_volume_threshold: 1).request_volume_threshold
      end

      def test_defaults_error_threshold_percentage
        assert_equal 50, @object.error_threshold_percentage
      end

      def test_allows_overriding_error_threshold_percentage
        assert_equal 12, Properties.new(error_threshold_percentage: 12).error_threshold_percentage
      end

      def test_defaults_window_size_in_seconds
        assert_equal 60, @object.window_size_in_seconds
      end

      def test_allows_overriding_window_size_in_seconds
        assert_equal 120, Properties.new(window_size_in_seconds: 120).window_size_in_seconds
      end

      def test_defaults_bucket_size_in_seconds
        assert_equal 10, @object.bucket_size_in_seconds
      end

      def test_allows_overriding_bucket_size_in_seconds
        assert_equal 2, Properties.new(bucket_size_in_seconds: 2).bucket_size_in_seconds
      end

      def test_raises_bucket_size_greater_than_window_size
        assert_raises ArgumentError do
          Properties.new({
            window_size_in_seconds: 8,
            bucket_size_in_seconds: 10,
          })
        end
      end

      def test_raises_bucket_size_equal_to_window_size
        assert_raises ArgumentError do
          Properties.new({
            window_size_in_seconds: 8,
            bucket_size_in_seconds: 8,
          })
        end
      end

      def test_raises_if_window_size_not_perfectly_divisible_by_bucket_size
        assert_raises ArgumentError do
          Properties.new({
            window_size_in_seconds: 21,
            bucket_size_in_seconds: 4,
          })
        end
      end
    end
  end
end
