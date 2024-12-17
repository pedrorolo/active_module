# ActiveModule

*"Let's turn modules and classes into first-class active record values!"*

ActiveModel/ActiveRecord implementation of the Module attribute type.

- Allows storing a reference to a `Module` or `Class` (because they are modules) in a `:string` 
database field in a safe and efficient way.
- It automatically casts strings and symbols into modules when creating and querying objects.
- Symbols or strings refer to the modules using unqualified names.

This is a very generic mechanism that enables many possible utilizations, for instance:
- Strategy Pattern (composition-based polymorphism)
- Rapid prototyping static domain objects
- Static configuration management
- Rich Java/C#-like enums

You can find examples of these in [Usage -> Examples :](#Examples) 

## Installation

Add to your gemfile - and if you are using rails - that's all you need:

```ruby
gem 'active_module', "~>0.1"
```

If you are not using rails, just issue this command after loading active record

```ruby
ActiveModule.register!
```

or this, if you prefer to have a better idea of what you are doing:

```ruby
ActiveModel::Type.register(:active_module, ActiveModule::Base)
ActiveRecord::Type.register(:active_module, ActiveModule::Base)
```


## Usage

Add a string field to the table you want to hold a module attribute in your migrations
```ruby
create_table :my_ar_objects do |t|
  t.string :module_field
end
```

Now given this module structure:
```ruby
class MyARObject < ActiveRecord::Base
  module MyModule1; end
  module MyModule2; end
  class MyClass; 
    module Module1; end
  end
end
```
You can make the field refer to one of these modules/classes like this:
```ruby
class MyARObject < ActiveRecord::Base
  attribute :module_field, 
            :active_module, 
            possible_modules: [MyModule1, MyModule2, MyClass, MyClass::Module1]
end
```
And this is it! Easy!<br>

### Assigning and querying module attributes
Now you can use this attribute in many handy ways:
<br>
<br>
For instance, you may refer to it using module literals:
```ruby
MyARObject.create!(module_field: MyARObject::MyModule1)

MyARObject.where(module_field: MyARObject::MyModule1)

my_ar_object.module_field = MyARObject::MyModule1

my_ar_object.module_field #=> MyARObject::MyModule1:Module

```
But as typing fully qualified module names is not very ergonomic, you may also use symbols instead:

```ruby
MyARObject.create!(module_field: :MyClass)

MyARObject.where(module_field: :MyClass)

my_ar_object.module_field = :MyClass

my_ar_object.module_field #=> MyARObject::MyClass:Class

```

However, if there is the need for disambiguation, you can always use strings instead:

```ruby

MyARObject.create!(module_field: "MyClass::MyModule1")

MyARObject.where(module_field: "MyClass::MyModule1")

my_ar_object.module_field = "MyClass::MyModule1"

my_ar_object.module_field #=> MyARObject::MyClass::MyModule::Module
```

### Comparing modules with strings and symbols

In order to compare modules with Strings or Symbols you'll have to use the `ActiveModule::Comparison`
refinement. This refinement adds the method `Module#=~` to the `Module` class, but this change is
only available within the namespace that includes the refinement.

```ruby
module YourClassOrModuleThatWantsToCompare
  using ActiveModule::Comparison
  def method_that_compares
    my_ar_object.module_field =~ :MyModule1
  end
end

## Examples

### Strategy Pattern (composition-based polymorphism)

[The Strategy design pattern](https://en.wikipedia.org/wiki/Strategy_pattern) allows composition based polymorphism. This enables runtime polymorphism (by changing the strategy in runtime), 
and multiple-polymorphism (by composing an object of multiple strategies).

```ruby
class MyARObject < ActiveRecord::Base
  module Strategy1
    def self.call
      "strategy1 called"
    end
  end

  module Strategy2
    def self.call
      "strategy2 called"
    end
  end

  attribute :strategy, 
            :active_module, 
            possible_modules: [Strategy1, Strategy2]

  def run_strategy!
    # here we could pass arguments to the strategy, and if 
    # in this case strategies were classes we could also 
    # instantiate them
    strategy.call
  end
end

MyARObject.create!(module_field: :Strategy1).run_strategy! #=> "strategy1 called"
MyARObject.create!(module_field: :Strategy1).run_strategy! #=> "strategy2 called"
```


### Rapid prototyping static domain objects

```ruby 
# Provider domain Object
module Provider
 # As if the domain model class
  def self.all
    [Ebay, Amazon]
  end

  # As if the domain model instances
  module Ebay
    def self.do_something!
      "do something with the ebay provider config"
    end
  end

  module Amazon
    def self.do_something!
      "do something with the amazon provider config"
    end
  end
end

class MyARObject < ActiveRecord::Base
  attribute :provider, 
            :active_module, 
            possible_modules: Provider.all
end

MyARObject.create!(provider: :Ebay).provier.do_something! 
  #=> "do something with the ebay provider config"
MyARObject.create!(provider: Provider::Amazon).provider.do_something! 
  #=> "do something with the amazon provider config"
```

What is interesting about this is that we can later easily promote
our provider objects into full fledged ActiveRecord objects without 
big changes to our code:
```ruby
class Provider < ActiveRecord::Base
  def do_something!
    #...
  end
end

class MyARObject < ActiveRecord::Base
  belongs_to :provider
end
```

Just in case you'd like to have shared code amongst the instances in the above example, 
this is how you could do so:

```ruby 
# Provider domain Object
module Provider
  # As if the domain model class
  module Base 
    def do_something!
      "do something with #{something_from_an_instance}"
    end
  end

  # As if the domain model instances
  module Ebay
    include Base
    extend self

    def something_from_an_instance
      "the ebay provider config"
    end
  end

  module Amazon
    include Base
    extend self

    def something_from_an_instance
      "the amazon provider config"
    end
  end

  # As if the domain model class
  def self.all
    [Ebay, Amazon]
  end
end
```


### Static configuration management

This example is not much different than previous one. It however stresses that the module we
refer to might be used as a source of configuration parameters that change the behaviour of 
the class it belongs to:

```ruby 
# Provider domain Object
module ProviderConfig
  module Ebay
    module_function

    def url= 'www.ebay.com'
    def number_of_attempts= 5 
  end

  module Amazon
    module_function

    def url= 'www.amazon.com'
    def number_of_attempts= 10
  end

  def self.all
    [Ebay, Amazon]
  end
end

class MyARObject < ActiveRecord::Base
  attribute :provider_config, 
            :active_module, 
            possible_modules: ProviderConfig.all

  def load_page!
    n_attempts = 0
    result = nil
    while n_attempts < provider.number_of_attempts
      result = get_page(provider.url)
      if(result)
        return result
      else
        n_attempts.inc
      end
    end
    result
  end
end

MyARObject.create!(provider_config: :Ebay).load_page!
```

### Rich Java/C#-like enums
This example is only to show the possibility. 
This would probably benefit from using a meta programming abstraction
and there are already gems with this kind of functionality such as `enumerizable`

In a real world project, I guess it would rather make sense to extend `ActiveModule::Base` or even `ActiveModel::Type::Value`. But here it goes for the sake of example.

Java/C# enums allow defining methods on the enum, which are shared across all enum values:

```ruby
module PipelineStage
  module Base
    def external_provider_code
      @external_provider_code ||= self.name.underscore
    end

    def database_representation
      self.name
    end

    def frontend_representation
      @frontend_representation ||= self.name.demodulize.upcase
    end
  end

  module InitialContact
    extend Base
  end

  module InNegotiations
    extend Base
  end

  module LostDeal
    extend Base
  end

  module PaidOut
    extend Base
  end

  module_function

  def all
    [InitialContact, InNegotiations, LostDeal, PaidOut]
  end

  def cast(stage)
    self.all.map(&:external_provider_code).find{|code| code == stage} ||
    self.all.map(&:database_representation).find{|code| code == stage} ||
    self.all.map(&:frontend_representation).find{|code| code == stage} 
  end
end

class MyARObject < ActiveRecord::Base
  attribute :pipeline_stage, 
            :active_module, 
            possible_modules: PipelineStage.all
end

object = MyARObject.new(pipeline_stage: :InitialStage)
object.pipeline_stage&.frontend_representation #=> "INITIAL_STAGE"
object.pipeline_stage = :InNegotiations
object.pipeline_stage&.database_representation #=> "PipelineStage::InNegotiations"
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pedrorolo/active_module.
