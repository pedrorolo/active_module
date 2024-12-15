# ActiveModule

ActiveModel/ActiveRecord implementation of the Module attribute type. 

It allows storing a reference to a `Module` or `Class` in a `:string` database field in a safe way

It automatically casts strings and symbols into modules for the purposes of object creation 
and querying.

The original idea behind this functionality was to enable idiomatic and duck typed implementations
of the strategy design pattern. However, this is a very generic mechanism that enables many possible 
utilizations, for instance:
- Strategy Pattern: Composition based polymorphism
- Rapid prototyping static domain objects without persisting them
- Assigning a field with one Configuration from a list of static configurations
- Rich Java/C#-like enums

We provide examples for these usages in [Usage -> Examples :](#Examples) 

## Index

- [Index](#index)
- [Installation](#installation)
- [Usage](#usage)
  * [Examples](#examples)
    - [Strategy Design Pattern](#strategy-design-pattern)
    - [Rapid Prototying static domain objects without persistence](#rapid-prototying-static-domain-objects-without-persistence)
    - [Assigning a field with one Configuration from a list of static configurations](assigning-a-field-with-one-configuration-from-a-list-of-static-configurations)
    - [Rich Java/C#-like enums](#rich-javac-like-enums)

## Installation

<!-- TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG -->

Add to your gemfile:

```ruby
gem 'active_module', "~>0.0.1"
```

Add to a rails initializer, such as `intializers/types.rb`

```ruby
ActiveModule.register!
```

or

```ruby
ActiveModel::Type.register(:active_module, ActiveModule::Base)
ActiveRecord::Type.register(:active_module, ActiveModule::Base)
```


## Usage

```ruby
# migration
create_table :my_ar_objects do |t|
  t.string :module_field
end

class MyARObject < ActiveRecord::Base
  module MyModule1; end
  module MyModule2; end
  class MyClass; 
    module Module1; end
  end


  attribute :module_field, 
            :active_module, 
            possible_modules: [MyModule1, 
                              MyModule2, 
                              MyClass, 
                              MyClass::VeryNested]
end

object1 = MyARObject.create!(module_field: MyARObject::MyModule1)
object1.module_field #=> MyARObject::MyModule1:Module

object2 = MyARObject.create!(module_field: "MyModule2")
object2.module_field #=> MyARObject::MyModule2:Module

object3 = MyARObject.create!(module_field: :MyClass)
object3.module_field #=> MyARObject::MyClass:Module

object4 = MyARObject.create!(module_field: 'MyClass::Module1')


MyARObject.where(module_field: MyARObject::MyClass) #=> object3
MyARObject.where(module_field: "MyARObject::MyModule1") #=> object1
MyARObject.where(module_field: :MyModule2) #=> object2
MyARObject.where(module_field: "MyClass::MyModule1") #=> object4
```

### Examples

#### Strategy design pattern

[The Strategy design pattern](https://en.wikipedia.org/wiki/Strategy_pattern) allows composition based polymorphism. This enables runtime polymorphism (by changing the strategy in runtime), 
and multiple-polymorphism (by composing an object of multiple strategies).

```ruby
class MyARObject < ActiveRecord::Base
  module Strategy1
    module_function
    def call
      "strategy1 called"
    end
  end

  module Strategy2
    module_function
    def call
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

What is interesting about this is that we can later easily promote
our provider objects into full fledged Active::Record objects without 
minor changes to our code:
```ruby 
# Provider domain Object
module Provider
  extend self

  def all
    [Ebay, Amazon]
  end

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
end

class MyARObject < ActiveRecord::Base
  attribute :provider, 
            :active_module, 
            possible_modules: Provider.all
end

MyARObject.create!(provider: :Ebay).provier.do_something! 
  #=> "do something with the ebay provider config"
MyARObject.create!(module_field: Provider::Amazon).provider.do_something! 
  #=> "do something with the amazon provider config"
```

#### Assigning a field with one Configuration from a list of static configurations

What is interesting about this is that we can later easily promote
our provider objects into full fledged Active::Record objects without 
minor changes to our code:

```ruby 
# Provider domain Object
module ProviderConfig
  extend self

  def all
    [Ebay, Amazon]
  end

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
end

class MyARObject < ActiveRecord::Base
  attribute :provider_config, 
            :active_module, 
            possible_modules: Provider.all

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
This example is more to show the possibility. 
This would probably benefit from a meta programming abstraction
and there are already gems with this kind of functionality such as `enumerizable`

```ruby
module PipelineStage
  extend self
  def all
    [InitialContact; InNegotiations; LostDeal; PaidOut]
  end

  def cast(stage)
    self.all.map(&:external_provider_code).find{|code| code == stage} ||
    self.all.map(&:database_representation).find{|code| code == stage} ||
    self.all.map(&:frontend_representation).find{|code| code == stage} 
  end

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
    include Base
    extend self
  end

  module InNegotiations
    include Base
    extend self
  end

  module LostDeal
    include Base
    extend self
  end

  def PaidOut
    include Base
    extend self
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

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/active_module.
