## Mocha [![Build Status](https://travis-ci.org/freerange/mocha.svg?branch=master)](https://travis-ci.org/freerange/mocha) [![Gem Version](https://badge.fury.io/rb/mocha.svg)](http://badge.fury.io/rb/mocha) [![SemVer](https://api.dependabot.com/badges/compatibility_score?dependency-name=mocha&package-manager=bundler&version-scheme=semver)](https://dependabot.com/compatibility-score.html?dependency-name=mocha&package-manager=bundler&version-scheme=semver)


### Description

* A Ruby library for mocking and stubbing.
* A unified, simple and readable syntax for both full & partial mocking.
* Built-in support for MiniTest and Test::Unit.
* Supported by many other test frameworks.

### Installation

#### Gem

Install the latest version of the gem with the following command...

    $ gem install mocha

Note: If you are intending to use Mocha with Test::Unit or MiniTest, you should only setup Mocha *after* loading the relevant test library...

##### Test::Unit

```ruby
require 'rubygems'
gem 'mocha'
require 'test/unit'
require 'mocha/test_unit'
```

##### MiniTest

```ruby
require 'rubygems'
gem 'mocha'
require 'minitest/unit'
require 'mocha/minitest'
```

#### Bundler

If you're using Bundler, include Mocha in the `Gemfile` and then setup Mocha later once you know the test library has been loaded...

##### Test::Unit

```ruby
# Gemfile
gem "mocha"

# Elsewhere after Bundler has loaded gems e.g. after `require 'bundler/setup'`
require "test/unit"
require "mocha/test_unit"
```

##### MiniTest

```ruby
# Gemfile
gem "mocha"

# Elsewhere after Bundler has loaded gems e.g. after `require 'bundler/setup'`
require "minitest/unit"
require "mocha/minitest"
```

#### Rails

If you're loading Mocha using Bundler within a Rails application, you should setup Mocha manually e.g. at the bottom of your `test_helper.rb`.

##### MiniTest

```ruby
# Gemfile in Rails app
gem 'mocha'

# At bottom of test_helper.rb (or at least after `require 'rails/test_help'`)
require 'mocha/minitest'
```

##### RSpec

RSpec includes a mocha adapter. Just tell RSpec you want to mock with `:mocha`:

```ruby
# Gemfile in Rails app
gem 'mocha'

# Within `spec/spec_helper.rb`
RSpec.configure do |config|
  config.mock_with :mocha
end
```

Note: There is no need to use a require statement to setup Mocha; RSpec does this itself.

#### Rails Plugin

Install the Rails plugin...

    $ rails plugin install git://github.com/freerange/mocha.git

Note: As of version 0.9.8, the Mocha plugin is not automatically setup at plugin load time. Instead it must be manually setup e.g. at the bottom of your `test_helper.rb`.

##### MiniTest

```ruby
# At bottom of test_helper.rb (or at least after `require 'rails/test_help'`)
require 'mocha/minitest'
```

#### Known Issues

* In Mocha v1.2.0 there is a scenario where stubbing a class method originally defined in a module hangs the Ruby interpreter due to [a bug in Ruby v2.3.1](https://bugs.ruby-lang.org/issues/12832). See #272. This was fixed in Mocha v1.2.1.
* Since v1.1.0 Mocha has used prepended modules internally for stubbing methods. There is [an obscure Ruby bug](https://bugs.ruby-lang.org/issues/12876) in many (but not all) versions of Ruby between v2.0 & v2.3 which under certain circumstances may cause your Ruby interpreter to hang. See the Ruby bug report for more details. The bug has been fixed in Ruby v2.3.3 & v2.4.0.
* Stubbing an aliased class method, where the original method is defined in a module that's used to `extend` the class doesn't work in Ruby 1.8.x. See stub_method_defined_on_module_and_aliased_test.rb for an example of this behaviour.
* 0.13.x versions cause a harmless, but annoying, deprecation warning when used with Rails 3.2.0-3.2.12, 3.1.0-3.1.10 & 3.0.0-3.0.19.
* 0.11.x versions don't work with Rails 3.2.13 (`TypeError: superclass mismatch for class ExpectationError`). See #115.
* Versions 0.10.2, 0.10.3 & 0.11.0 of the Mocha gem were broken. Please do not use these versions.
* Versions 0.9.6 & 0.9.7 of the Mocha Rails plugin were broken. Please do not use these versions.

### Usage

#### Quick Start

```ruby
require 'test/unit'
require 'mocha/test_unit'

class MiscExampleTest < Test::Unit::TestCase
  def test_mocking_a_class_method
    product = Product.new
    Product.expects(:find).with(1).returns(product)
    assert_equal product, Product.find(1)
  end

  def test_mocking_an_instance_method_on_a_real_object
    product = Product.new
    product.expects(:save).returns(true)
    assert product.save
  end

  def test_stubbing_instance_methods_on_real_objects
    prices = [stub(:pence => 1000), stub(:pence => 2000)]
    product = Product.new
    product.stubs(:prices).returns(prices)
    assert_equal [1000, 2000], product.prices.collect {|p| p.pence}
  end

  def test_stubbing_an_instance_method_on_all_instances_of_a_class
    Product.any_instance.stubs(:name).returns('stubbed_name')
    product = Product.new
    assert_equal 'stubbed_name', product.name
  end

  def test_traditional_mocking
    object = mock('object')
    object.expects(:expected_method).with(:p1, :p2).returns(:result)
    assert_equal :result, object.expected_method(:p1, :p2)
  end

  def test_shortcuts
    object = stub(:method1 => :result1, :method2 => :result2)
    assert_equal :result1, object.method1
    assert_equal :result2, object.method2
  end
end
```

#### Mock Objects

```ruby
class Enterprise
  def initialize(dilithium)
    @dilithium = dilithium
  end

  def go(warp_factor)
    warp_factor.times { @dilithium.nuke(:anti_matter) }
  end
end

require 'test/unit'
require 'mocha/test_unit'

class EnterpriseTest < Test::Unit::TestCase
  def test_should_boldly_go
    dilithium = mock()
    dilithium.expects(:nuke).with(:anti_matter).at_least_once  # auto-verified at end of test
    enterprise = Enterprise.new(dilithium)
    enterprise.go(2)
  end
end
```

#### Partial Mocking

```ruby
class Order
  attr_accessor :shipped_on

  def total_cost
    line_items.inject(0) { |total, line_item| total + line_item.price } + shipping_cost
  end

  def total_weight
    line_items.inject(0) { |total, line_item| total + line_item.weight }
  end

  def shipping_cost
    total_weight * 5 + 10
  end

  class << self
    def find_all
      # Database.connection.execute('select * from orders...
    end

    def number_shipped_since(date)
      find_all.select { |order| order.shipped_on > date }.length
    end

    def unshipped_value
      find_all.inject(0) { |total, order| order.shipped_on ? total : total + order.total_cost }
    end
  end
end

require 'test/unit'
require 'mocha/test_unit'

class OrderTest < Test::Unit::TestCase
  # illustrates stubbing instance method
  def test_should_calculate_shipping_cost_based_on_total_weight
    order = Order.new
    order.stubs(:total_weight).returns(10)
    assert_equal 60, order.shipping_cost
  end

  # illustrates stubbing class method
  def test_should_count_number_of_orders_shipped_after_specified_date
    now = Time.now; week_in_secs = 7 * 24 * 60 * 60
    order_1 = Order.new; order_1.shipped_on = now - 1 * week_in_secs
    order_2 = Order.new; order_2.shipped_on = now - 3 * week_in_secs
    Order.stubs(:find_all).returns([order_1, order_2])
    assert_equal 1, Order.number_shipped_since(now - 2 * week_in_secs)
  end

  # illustrates stubbing instance method for all instances of a class
  def test_should_calculate_value_of_unshipped_orders
    Order.stubs(:find_all).returns([Order.new, Order.new, Order.new])
    Order.any_instance.stubs(:shipped_on).returns(nil)
    Order.any_instance.stubs(:total_cost).returns(10)
    assert_equal 30, Order.unshipped_value
  end
end
```

### Thread safety

Mocha is currently *not* thread-safe. There are two main reasons for this: (a) in multi-threaded code Mocha exceptions may be raised in a thread other than the one which is running the test and thus a Mocha exception may not be correctly intercepted by Mocha exception handling code; and (b) partial mocking changes the state of objects in the `ObjectSpace` which is shared across all threads in the Ruby process and this access to what is effectively global state is not synchronized.

### Expectation matching / invocation order

Stubs and expectations are basically the same thing. A stub is just an expectation of zero or more invocations. The `Expectation#stubs` method is syntactic sugar to make the intent of the test more explicit.

When a method is invoked on a mock object, the mock object searches through its expectations from newest to oldest to find one that matches the invocation. After the invocation, the matching expectation might stop matching further invocations.

See the [documentation](http://gofreerange.com/mocha/docs/Mocha/Mock.html) for `Mocha::Mock` for further details.

### Configuration

If you want, Mocha can generate a warning or raise an exception when:

* stubbing a method unnecessarily
* stubbing method on a non-mock object
* stubbing a non-existent method
* stubbing a non-public method

See the [documentation](http://gofreerange.com/mocha/docs/Mocha/Configuration.html) for `Mocha::Configuration` for further details.

### Useful Links

* [Official Documentation](http://gofreerange.com/mocha/docs/)
* [Source Code](http://github.com/freerange/mocha)
* [Mailing List](http://groups.google.com/group/mocha-developer)
* [James Mead's Blog](http://jamesmead.org/blog/)
* [An Introduction To Mock Objects In Ruby](http://jamesmead.org/talks/2007-07-09-introduction-to-mock-objects-in-ruby-at-lrug/)
* [Mocks Aren't Stubs](http://martinfowler.com/articles/mocksArentStubs.html)
* [Growing Object-Oriented Software Guided By Tests](http://www.growing-object-oriented-software.com/)
* [Mock Roles Not Objects](http://www.jmock.org/oopsla2004.pdf)
* [jMock](http://www.jmock.org/)

### Contributors

See this [list of contributors](https://github.com/freerange/mocha/graphs/contributors).

### Translations

* [Serbo-Croatian](http://science.webhostinggeeks.com/mocha) by [WHG Team](http://webhostinggeeks.com/). (may be out-of-date)

### Releasing a new version

* Update the RELEASE.md file with a summary of changes
* Bump the version in `lib/mocha/version.rb`
* Commit & push to Github
* Check Travis CI build is passing - https://travis-ci.org/freerange/mocha

* Sign in to rubygems.org and find API key - https://rubygems.org/profile/edit

```bash
$ curl -u james@floehopper.org https://rubygems.org/api/v1/api_key.yaml > ~/.gem/credentials; chmod 0600 ~/.gem/credentials`
```

* Sign in to Google Analytics - https://analytics.google.com/analytics/web/
* Find the web property ID for Go Free Range Ltd > Mocha Documentation (UA-45002715-2)

```bash
$ MOCHA_GENERATE_DOCS=true bundle install

$ MOCHA_GENERATE_DOCS=true GOOGLE_ANALYTICS_WEB_PROPERTY_ID=UA-45002715-2 rake release
mocha 1.2.0 built to pkg/mocha-1.2.0.gem.
Tagged v1.2.0.
Pushed git commits and tags.
Pushed mocha 1.2.0 to rubygems.org.
[runs tests]
[generates docs]
[deploys docs]
```

### History

Mocha was initially harvested from projects at [Reevoo](http://www.reevoo.com/). It's syntax is heavily based on that of [jMock](http://www.jmock.org).

### License

&copy; Copyright Revieworld Ltd. 2006

You may use, copy and redistribute this library under the same terms as [Ruby itself](http://www.ruby-lang.org/en/LICENSE.txt) or under the [MIT license](http://www.opensource.org/licenses/MIT).
