# Resilient

Some tools to aid in resiliency in ruby. For now, just a circuit breaker (~~stolen from~~ based on [hystrix](https://github.com/netflix/hystrix)). Soon much more...

Nothing asynchronous or thread safe yet either, but open to it and would like to see more around it in the future.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "resilient"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resilient

## Usage

```ruby
require "resilient/circuit_breaker"

# default properties for circuit, CircuitBreaker.get is used instead of
# CircuitBreaker.new as for keeps a registry of circuits by key to prevent
# creating multiple instances of the same circuit breaker for a key; not using
# `for` means you would have multiple instances of the circuit breaker and thus
# separate state and metrics; you can read more in examples/for_vs_new.rb
circuit_breaker = Resilient::CircuitBreaker.get(key: Resilient::Key.new("example"))
if circuit_breaker.allow_request?
  begin
    # do something expensive
    circuit_breaker.success
  rescue => boom
    circuit_breaker.failure
    # do fallback
  end
else
  # do fallback
end
```

customize properties of circuit:

```ruby
properties = Resilient::CircuitBreaker::Properties.new({
  # at what percentage of errors should we open the circuit
  error_threshold_percentage: 50,
  # do not try request again for 5 seconds
  sleep_window_seconds: 5,
  # do not open circuit until at least 5 requests have happened
  request_volume_threshold: 5,
})
circuit_breaker = Resilient::CircuitBreaker.get(properties: properties, key: Resilient::Key.new("example"))
# etc etc etc
```

force the circuit to be always open:

```ruby
properties = Resilient::CircuitBreaker::Properties.new(force_open: true)
circuit_breaker = Resilient::CircuitBreaker.get(properties: properties, key: Resilient::Key.new("example"))
# etc etc etc
```

force the circuit to be always closed (great way to test in production with no impact, all instrumentation still runs which means you can measure in production with config and gain confidence while never actually opening a circuit incorrectly):

```ruby
properties = Resilient::CircuitBreaker::Properties.new(force_closed: true)
circuit_breaker = Resilient::CircuitBreaker.get(properties: properties, key: Resilient::Key.new("example"))
# etc etc etc
```

customize rolling window to be 10 buckets of 1 second each (10 seconds in all):

```ruby
metrics = Resilient::CircuitBreaker::Metrics.new({
  window_size_in_seconds: 10,
  bucket_size_in_seconds: 1,
})
circuit_breaker = Resilient::CircuitBreaker.get(metrics: metrics, key: Resilient::Key.new("example"))
# etc etc etc
```

## Tests

To ensure that you have a clean circuit for each test case, be sure to run the following in the setup for your tests (which resets each registered circuit breaker) either before every test case or at a minimum each test case that uses circuit breakers.

```ruby
Resilient::CircuitBreaker.reset
```

## Development

```bash
# install dependencies
script/bootstrap

# run tests
script/test

# ...or to auto run tests with guard
script/watch

# to get a shell to play in
script/console
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jnunemaker/resilient.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Release (for maintainers)

* increment version based on semver
* git commit version change
* script/release (releases to rubygems and git tags)
