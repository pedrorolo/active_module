
# active_module
[![Gem Version](https://img.shields.io/gem/v/active_module)](https://rubygems.org/gems/active_module)
[![License: MIT](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/pedrorolo/active_module/main.yml)](https://github.com/pedrorolo/active_module/blob/main/Rakefile)
[![100% Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)](https://github.com/pedrorolo/active_module/blob/main/spec/spec_helper.rb)
[![Gem Total Downloads](https://img.shields.io/gem/dt/active_module?style=flat)](https://bestgems.org/gems/active_module)



#### *Modules and Classes as first-class active record values!*

ActiveModel/ActiveRecord implementation of the Module attribute type.

- Allows storing a reference to a `Module` or `Class` in a `:string` database field
- Automatically casts strings and symbols into modules when creating and querying objects
- Symbols or strings refer to the modules using unqualified names
- It is safe and efficient

This is a very generic mechanism that enables many possible utilizations, for instance:
- **Composition-based polymorphism (Strategy design pattern)**
- **Rapid prototyping static domain objects**
- **Static configuration management**
- **Rich Java/C#-like enums**

You can find examples of these in [Usage -> Examples](#Examples).

## TL;DR

Declare module attributes like this:
```ruby
class MyARObject < ActiveRecord::Base
  attribute :module_field, 
            :active_module, 
            possible_modules: [MyModule1, MyClass, Nested::Module]
end
```

Assign them like this:
```ruby 
object.module_field = Nested::Module
object.module_field = :Module
object.module_field = "Module"
object.module_field = :nested_module          # underscored nested name
object.module_field #=> Nested::Module:Module
```

Query them like this:
```ruby 
MyARObject.where(module_field: Nested::Module)
MyARObject.where(module_field: :Module)
MyARObject.where(module_field: "Module")
MyARObject.where(module_field: :nested_module) # underscored nested name
object.module_field #=> Nested::Module:Module
```

And compare them like this:

```ruby 
object.module_field == Nested::Module

module MyNameSpace
  using ActiveModule::Comparison

  object.module_field =~ :Module
  object.module_field =~ "Module"
  object.module_field =~ :nested_module     # underscored nested name
end
```

## Installation

Add to your gemfile - and if you are using rails - that's all you need:

```ruby
gem 'active_module', "~> 0.6"
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
  t.string :module_field, index: true
end
```

Now given this random module hierarchy:
```ruby
class MyARObject < ActiveRecord::Base
  module MyModule1; end
  module MyModule2; end
  class MyClass; 
    module MyModule1; end
  end
end
```
You can make the field refer to one of these modules/classes like this:
```ruby
class MyARObject < ActiveRecord::Base
  attribute :module_field, 
            :active_module, 
            possible_modules: [MyModule1, MyModule2, MyClass, MyClass::MyModule1]
end
```

Optionally, you can specify how to map your modules into the database
(the default is the module's fully qualified name):
```ruby
attribute :module_field, 
          :active_module, 
          possible_modules: [MyModule1, MyModule2, MyClass, MyClass::MyModule1],
          mapping: {MyModule1 => "m1"}
```

Modules not included in the mapping hash will use their fully qualified
name as the database representation. Assignment and querying still work
with module literals, symbols, and strings:

```ruby
my_ar_object.module_field = :MyModule1
my_ar_object.module_field #=> MyARObject::MyModule1:Module

MyARObject.where(module_field: :MyModule1)
```

The mapping only affects what is stored in the database column.

And this is it! Easy!<br>

### Assigning and querying module attributes
Now you can use this attribute in many handy ways!
<br>
<br>

The most ergonomic way is to use underscored symbols. For flat modules,
use the underscored name directly:

```ruby
MyARObject.create!(module_field: :my_module1)

MyARObject.where(module_field: :my_module1)

my_ar_object.module_field = :my_module1

my_ar_object.module_field #=> MyARObject::MyModule1:Module
```

Nested modules can be referenced using underscored symbols at any
nesting level:

```ruby
MyARObject.create!(module_field: :my_class_my_module1)  # partial nesting
MyARObject.create!(module_field: :my_module1)           # demodulized name
MyARObject.where(module_field: :my_class_my_module1)    # all segments joined

my_ar_object.module_field = :my_class_my_module1
my_ar_object.module_field #=> MyARObject::MyClass::MyModule1:Module
```

When a demodulized name is ambiguous (shared by modules at different
nesting levels), the least-nested module always wins for assignment
and querying:

```ruby
# Given possible_modules: [MyModule1, MyClass::MyModule1]
# :MyModule1 resolves to the flat MyModule1 (not MyClass::MyModule1)

MyARObject.create!(module_field: :MyModule1)   # sets to MyModule1
MyARObject.where(module_field: :MyModule1)     # filters by MyModule1
my_ar_object.module_field = :MyModule1         # assigns MyModule1

# Use the underscored nested name for the nested module
MyARObject.where(module_field: :my_class_my_module1)  # filters by MyClass::MyModule1
```

You can always refer to modules using their fully qualified names
via symbols or module literals:

```ruby
MyARObject.create!(module_field: :MyModule1)
MyARObject.create!(module_field: MyARObject::MyModule1)

MyARObject.where(module_field: :MyModule1)
MyARObject.where(module_field: MyARObject::MyModule1)
```

And if there is the need for disambiguation, you can always use
fully qualified strings:

```ruby
MyARObject.create!(module_field: "MyClass::MyModule1")

MyARObject.where(module_field: "MyClass::MyModule1")

my_ar_object.module_field = "MyClass::MyModule1"

my_ar_object.module_field #=> MyARObject::MyClass::MyModule1:Module
```

### Comparing modules with strings and symbols

In order to compare modules with Strings or Symbols you'll have to use the `ActiveModule::Comparison`
refinement. This refinement adds the method `Module#=~` to the `Module` class, but this change is
only available within the namespace that includes the refinement.

```ruby
module YourClassOrModuleThatWantsToCompare
  using ActiveModule::Comparison

  def method_that_compares
    my_ar_object.module_field =~ :my_module1          # underscored name
    my_ar_object.module_field =~ :my_class_my_module1 # nested underscored
    my_ar_object.module_field =~ "MyClass::MyModule1" # fully qualified string
  end
end
```

or like this, if you don't want to use the refinement:

```ruby
ActiveModule::Comparison.compare(my_ar_object.module_field, :my_module1)
```

but in this last case it would probably make more sense to simply use a module literal:

```ruby
my_ar_object.module_field == MyClass::MyModule1
```


## Examples

### Composition-based polymorphism (Strategy design pattern)

[The Strategy design pattern](https://en.wikipedia.org/wiki/Strategy_pattern) allows composition based polymorphism. This enables runtime polymorphism (by changing the strategy in runtime), 
and multiple-polymorphism (by composing an object of multiple strategies).

If you want to use classes this will do: 
```ruby
class MyARObject < ActiveRecord::Base
  attribute :strategy_class, :active_module, possible_modules: StrategySuperclass.subclasses

  def strategy
    @strategy ||= strategy_class.new(some_args_from_the_instance)
  end

  def run_strategy!(args)
    strategy.call(args)
  end
end
```

But if you are not in the mood to define a class hierarchy for it (or if you are performance-savy),
you may use modules instead:

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

  def run_strategy!(some_args)
    strategy.call(some_args, other_args)
  end
end

MyARObject.create!(module_field: :Strategy1).run_strategy! #=> "strategy1 called"
MyARObject.create!(module_field: :Strategy2).run_strategy! #=> "strategy2 called"
```

You can later easily promote these modules to classes if you need instance variables:

```ruby
class MyARObject < ActiveRecord::Base
  class Strategy1
    def self.call
      self.new.call
    end

    def call
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

  def run_strategy!(some_args)
    strategy.call(some_args, other_args)
  end
end

MyARObject.create!(module_field: :Strategy1).run_strategy! #=> "strategy1 called"
MyARObject.create!(module_field: :Strategy2).run_strategy! #=> "strategy2 called"
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
  def self.all
    [Ebay, Amazon]
  end

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

### Rich Java/C#-like enums with `active_module_enum`

Java/C# enums allow defining methods on the enum, which are shared across all enum values.
ActiveModule supports this pattern with `active_module_enum`, which generates query, bang,
and scope methods for your active_module attributes.

Nested modules can always be referenced using underscored names at any level of nesting.
For example, given a deeply nested module:

```ruby
module Lime
  module Banana
    module Strawberry; end
  end
end

class MyARObject < ActiveRecord::Base
  attribute :fruit,
            :active_module,
            possible_modules: [Lime::Banana::Strawberry]
end
```

All of the following resolve to `Lime::Banana::Strawberry`:

```ruby
MyARObject.create!(fruit: :strawberry)              # last segment only
MyARObject.create!(fruit: :banana_strawberry)        # last two segments
MyARObject.create!(fruit: :lime_banana_strawberry)  # all segments
```

This also works for querying:

```ruby
MyARObject.where(fruit: :banana_strawberry)
```

And for comparison (with `ActiveModule::Comparison`):

```ruby
module MyModuleOrClass
  using ActiveModule::Comparison

  def self.match?(mod, value)
    mod =~ value
  end
end

MyModuleOrClass.match?(Lime::Banana::Strawberry, :banana_strawberry) #=> true
```

#### `active_module_enum` — generating query, bang, and scope methods

The `active_module_enum` method generates Rails-enum-style convenience methods
for your active_module attributes:

```ruby
module PipelineStage
  module_function

  def all
    [InitialContact, InNegotiations, LostDeal, PaidOut]
  end

  module Base
    def external_provider_code
      @external_provider_code ||= self.name.underscore
    end

    def frontend_representation
      @frontend_representation ||= self.name.demodulize.upcase
    end
  end

  module InitialContact; extend Base; end
  module InNegotiations; extend Base; end
  module LostDeal; extend Base; end
  module PaidOut; extend Base; end
end

class MyARObject < ActiveRecord::Base
  attribute :pipeline_stage,
            :active_module,
            possible_modules: PipelineStage.all

  active_module_enum :pipeline_stage
end
```

This generates:

```ruby
# Instance query methods (?)
object = MyARObject.new(pipeline_stage: :initial_contact)
object.initial_contact?                    #=> true
object.lost_deal?                          #=> false

# Instance bang methods (!) — set and save
object.initial_contact!
object.reload
object.pipeline_stage #=> PipelineStage::InitialContact

# Class-level scopes
MyARObject.with_initial_contact            #=> ActiveRecord::Relation
MyARObject.with_lost_deal                  #=> ActiveRecord::Relation

# Class-level query methods (same as scopes)
MyARObject.initial_contact                 #=> ActiveRecord::Relation
```

The `pluralized attribute name` method returns a hash mapping
modules to their fully qualified names:

```ruby
MyARObject.statuses        #=> { MyModule1 => "MyModule1", MyModule2 => "MyModule2" }
MyARObject.statuses.keys   #=> [MyModule1, MyModule2]
MyARObject.statuses.values #=> ["MyModule1", "MyModule2"]
```

All forms of underscored symbol names work for assignment and querying:

```ruby
MyARObject.create!(pipeline_stage: :initial_contact)
MyARObject.create!(pipeline_stage: :in_negotiations)
MyARObject.where(pipeline_stage: :lost_deal)
MyARObject.where(pipeline_stage: :paid_out)
```

For nested modules, methods are generated at **all nesting levels**:

```ruby
module Lime
  module Banana
    module Strawberry; end
  end
end

class Fruit < ActiveRecord::Base
  attribute :kind, :active_module,
            possible_modules: [Lime::Banana::Strawberry]
  active_module_enum :kind
end

object = Fruit.new(kind: :strawberry)
object.strawberry?                 #=> true
object.banana_strawberry?          #=> true (partial nesting)
object.lime_banana_strawberry?    #=> true (full nesting)

Fruit.with_banana_strawberry       #=> ActiveRecord::Relation
```

The `fields` method also works with nested modules. Each module gets
the shortest unique underscored name as its key (least-nested wins):

```ruby
module StatusA; end
module StatusB; end
module Nested
  module StatusA; end
  module StatusB; end
end

class Fruit < ActiveRecord::Base
  attribute :kind, :active_module,
            possible_modules: [StatusA, StatusB,
                               Nested::StatusA, Nested::StatusB]
  active_module_enum :kind
end

Fruit.kinds
#=> { StatusA => "StatusA", StatusB => "StatusB",
#     Nested::StatusA => "Nested::StatusA",
#     Nested::StatusB => "Nested::StatusB" }
```

All underscored forms work for assignment and querying:

```ruby
Fruit.create!(kind: :strawberry)
Fruit.create!(kind: :banana_strawberry)
Fruit.create!(kind: :lime_banana_strawberry)
Fruit.where(kind: :banana_strawberry)
```

##### Options

`active_module_enum` accepts the same options as Rails' `enum` method
(except for the values hash, which comes from `possible_modules`):

```ruby
active_module_enum :pipeline_stage,
                   prefix: true,       # prefix method names with the attribute name
                   suffix: true,       # suffix method names with the attribute name
                   scope: true,        # generate with_ scopes (default: true)
                   instance_methods: true,  # generate ? and ! methods (default: true)
                   on_ambiguous: :warn # :warn or :silence (default: :warn)
```

- **`prefix: true`** — prefixes methods with the attribute name:
  `pipeline_stage_initial_contact?`, `with_pipeline_stage_initial_contact`
- **`prefix: "custom"`** — prefixes with a custom string:
  `custom_initial_contact?`, `with_custom_initial_contact`
- **`suffix: true`** — suffixes methods with the attribute name:
  `initial_contact_pipeline_stage?`, `with_initial_contact_pipeline_stage`
- **`suffix: "custom"`** — suffixes with a custom string:
  `initial_contact_custom?`, `with_initial_contact_custom`
- **`scope: false`** — skips scope generation
- **`instance_methods: false`** — skips `?` and `!` method generation
- **`on_ambiguous: :silence`** — suppresses warnings when multiple
  modules share the same demodulized name (e.g. `Tino` and
  `Banana::Tino` both producing `tino?`)

##### Ambiguity resolution

When two modules at different nesting levels produce the same demodulized
name (e.g. `Status` and `Nested::Status` both mapping to `status?`),
**the least-nested module always wins** across all contexts —
assignment, querying, scopes, and enum methods:

```ruby
module Status; end
module Nested
  module Status; end
end

class MyARObject < ActiveRecord::Base
  attribute :status, :active_module,
            possible_modules: [Status, Nested::Status]
  active_module_enum :status
end

# Assignment resolves to the flat module
object = MyARObject.new(status: :status)
object.status         #=> Status (flat, not Nested::Status)

# Querying resolves to the flat module
MyARObject.where(status: :status)       # filters by Status
MyARObject.find_by(status: "Status")    # finds Status

# Enum query resolves to the flat module
object.status?        #=> true (matches Status)
object.nested_status? #=> true (use underscored name for Nested::Status)

# Bang method resolves to the flat module
object.status!
object.reload
object.status         #=> Status
```

To access the nested module, always use its underscored form:

```ruby
object.nested_status?         #=> true
object.nested_status!         #=> sets to Nested::Status
MyARObject.with_nested_status #=> ActiveRecord::Relation filtering by Nested::Status
```

This resolution applies consistently to `with_` scopes, class-level
query methods, `find_by`/`where`, and assignment via symbol or string —
the least-nested module wins for the ambiguous name:

```ruby
MyARObject.create!(status: Nested::Status)
MyARObject.create!(status: Status)

MyARObject.status.count          #=> 1 (flat Status only)
MyARObject.with_nested_status.count #=> 1 (Nested::Status only)
```

Note: when both `prefix: true` and `suffix: true` are set, only `prefix` takes
effect (matching Rails enum behavior).


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pedrorolo/active_module.
