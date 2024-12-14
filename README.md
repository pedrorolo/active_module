# ActiveModule

ActiveModel/ActiveRecord implementation of the Module attribute type. 

It allows storing a reference to a `Module` or `Class` in a `:string` database field in a safe way

It automatically casts strings and symbols into modules for the purposes of object creation 
and querying. 

Symbols or strings can both refer to the qualified and unqualified module names, 
allowing disambiguation in the case of need. 

The original idea behind this functionality was to enable idiomatic and duck typed implementations
of the strategy design pattern. However, this is a very generic mechanism that enables many possible 
utilizations, for instance:
- **Strategy Pattern: composition-based polymorphism**
- **Rapid prototyping static domain objects without persisting them**
- **Assigning a field with one Configuration from a list of static configurations**
- **Rich Java/C#-like enums**

We provide examples for these usages in [Usage -> Examples :](#Examples) 

## Index

- [Index](#index)
- [Installation](#installation)
- [Usage](#usage)
  * [Examples](#examples)
    - [Strategy Design Pattern](#strategy-design-pattern)
      - [State Design Pattern](#state-design-pattern)
    - [Rapid Prototying static domain objects without persistence](#rapid-prototying-static-domain-objects-without-persistence)
    - [Assigning a field with one Configuration from a list of static configurations](assigning-a-field-with-one-configuration-from-a-list-of-static-configurations)
    - [Rich Java/C#-like enums](#rich-javac-like-enums)
- [Developing](#developing)
- [Usage](#contributing)


## Installation

Add to your gemfile:

```ruby
gem 'active_module', "~>0.1"
```

Add to a rails initializer, such as `intializers/types.rb`

```ruby
ActiveModule.register!
```

or this

```ruby
ActiveModel::Type.register(:active_module, ActiveModule::Base)
ActiveRecord::Type.register(:active_module, ActiveModule::Base)
```


## Usage

```ruby
# in the migration
create_table :my_ar_objects do |t|
  t.string :module_field
end
```

```ruby
class MyARObject < ActiveRecord::Base
  module MyModule1; end
  module MyModule2; end
  class MyClass; 
    module Module1; end
  end


  attribute :module_field, 
            :active_module, 
            possible_modules: [MyModule1, MyModule2, MyClass, MyClass::Module1]
end

# it accepts modules
object1 = MyARObject.create!(module_field: MyARObject::MyModule1)

object1.module_field #=> MyARObject::MyModule1:Module


# it accepts symbols with unqualified module names
object3 = MyARObject.create!(module_field: :MyClass)

object3.module_field #=> MyARObject::MyClass:Class

# it accepts strings with unqualified module names
object2 = MyARObject.create!(module_field: "MyModule2")

object2.module_field #=> MyARObject::MyModule2:Module

# it accepts strings with unqualified module names for disambiguation
object4 = MyARObject.create!(module_field: 'MyClass::Module1')

object3.module_field #=> MyARObject::MyClass::Module1:Module


# the same values are valid in queries
MyARObject.where(module_field: MyARObject::MyClass) #=> object3
MyARObject.where(module_field: :MyModule2) #=> object2
MyARObject.where(module_field: "MyARObject::MyModule1") #=> object1
MyARObject.where(module_field: "MyClass::MyModule1") #=> object4

# and in assignments
object = MyARObject.new
object.module_field = MyARObject::MyClass
object.module_field #=> MyARObject::MyClass:Class

object.module_field = :MyModule2
object.module_field #=> MyARObject::MyModule2:Module

object.module_field = "MyARObject::MyModule1"
object.module_field #=> MyARObject::MyModule1:Module

object.module_field = "MyClass::MyModule1"
object.module_field #=> MyARObject::MyClass::Module1:Module
```

### Examples

#### Strategy design pattern

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


#### Rapid Prototying static domain objects without persistence

##### Without a Base module

```ruby 
# Provider domain Object
module Provider

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

  # As if the domain model class
  def self.all
    [Ebay, Amazon]
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
our provider objects into full fledged Active::Record objects without 
big changes to our code:
```ruby
class Provider < ActiveRecord::Base
  has_many :my_ar_objects

  def something_from_an_instance
    #....
  end
end

class MyARObject < ActiveRecord::Base
  belongs_to :provider
end
```

##### With a Base module

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


#### Assigning a field with one Configuration from a list of static configurations

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

#### Rich Java/C#-like enums
This example is only to show the possibility. 
This would probably benefit from a meta programming abstraction
and there are already gems with this kind of functionality such as `enumerizable`

I guess it would rather make sense to extend ActiveModule::Base or even ActiveModel::Type::Value 
in order to implement such functionality

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

  def PaidOut
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
object.pipeline_stage&.frontend_representation #=> INITIAL_STAGE
object.pipeline_stage = :InNegotiations
object.pipeline_stage&.database_representation #=> "PipelineStage::InNegotiations"
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pedrorolo/active_module.
