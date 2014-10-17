<!--
[![Gem Version](http://img.shields.io/gem/v/guard-scss-lint.svg)](http://badge.fury.io/rb/guard-scss-lint)
-->

[![Dependency Status](http://img.shields.io/gemnasium/arkbot/guard-scss-lint.svg)](https://gemnasium.com/arkbot/guard-scss-lint)
[![Build Status](https://travis-ci.org/arkbot/guard-scss-lint.svg?branch=master)](https://travis-ci.org/arkbot/guard-scss-lint)
[![Coverage Status](http://img.shields.io/coveralls/arkbot/guard-scss-lint/master.svg)](https://coveralls.io/r/arkbot/guard-scss-lint)
[![Coverage Status](https://img.shields.io/coveralls/arkbot/guard-scss-lint/master.svg)](https://coveralls.io/r/arkbot/guard-scss-lint)
[![Code Climate](http://img.shields.io/codeclimate/github/arkbot/guard-scss-lint.svg)](https://codeclimate.com/github/arkbot/guard-scss-lint)

# guard-scss-lint

**guard-scss-lint** allows you to automatically check Ruby code style with [scss-lint](https://github.com/causes/scss-lint/) when files are modified.

Tested on MRI 1.9, 2.0, 2.1, JRuby in 1.9 mode and Rubinius.

## Installation

Please make sure to have [Guard](https://github.com/guard/guard) installed before continue.

Add `guard-scss-lint` to your `Gemfile`:

```ruby
group :development do
  gem 'guard-scss-lint'
end
```

and then execute:

```sh
$ bundle install
```

or install it yourself as:

```sh
$ gem install guard-scss-lint
```

Add the default Guard::ScssLint definition to your `Guardfile` by running:

```sh
$ guard init scsslint
```

## Usage

Please read the [Guard usage documentation](https://github.com/guard/guard#readme).

## Options

You can pass some options in `Guardfile` like the following example:

```ruby
guard :scsslint, all_on_start: false do
  # ...
end
```

### Available Options

```ruby
all_on_start: true     # Check all files at Guard startup.
                       #   default: true
cli: '--some-opts'     # Pass arbitrary scss-lint CLI arguments.
                       # An array or string is acceptable.
                       #   default: nil
keep_failed: true      # Keep failed files until they pass.
                       #   default: true
notification: :failed  # Display Growl notification after each run.
                       #   true    - Always notify
                       #   false   - Never notify
                       #   :failed - Notify only when failed
                       #   default: :failed
```

## Advanced Tips

If you're using a testing Guard plugin such as [`guard-rspec`](https://github.com/guard/guard-rspec) together with `guard-scss-lint` in the TDD way (the red-green-refactor cycle),
you might be uncomfortable with the offense reports from scss-lint in the red-green phase:

* In the red-green phase, you're not necessarily required to write clean code – you just focus writing code to pass the test. It means, in this phase, `guard-rspec` should be run but `guard-scss-lint` should not.
* In the refactor phase, you're required to make the code clean while keeping the test passing. In this phase, both `guard-rspec` and `guard-scss-lint` should be run.

In this case, you may think the following `Guardfile` structure useful:

```ruby
# This group allows to skip running scss-lint when RSpec failed.
group :red_green_refactor, halt_on_fail: true do
  guard :rspec do
    # ...
  end

  guard :scsslint do
    # ...
  end
end
```

Note: You need to use `guard-rspec` 4.2.3 or later due to a [bug](https://github.com/guard/guard-rspec/pull/234) where it unintentionally fails when there are no spec files to be run.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## MIT License

See the [LICENSE.txt](LICENSE.txt) for details.

## Credits

This gem is a fork of [`guard-rubocop`](https://github.com/bbatsov/rubocop/). Yuji Nakayama's work on `guard-rubocop` made this project possible amidst my numerous time constraints.
