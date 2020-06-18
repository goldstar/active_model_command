# ActiveModel::Command

ActiveModel::Command is a way to add CQRS-style service objects to your project. It was inspired by [SimpleCommand](https://github.com/nebulab/simple_command) and Kickstarters [Lib::Command](https://github.com/pcreux/event-sourcing-rails-todo-app-demo/blob/master/app/models/lib/command.rb) and essentially combines them into a unified interface. 

Benefits of ActiveModel::Command:

* The command is an ActiveModel::Model. No need to define initialize but you still can if you want.
* ActiveModel::Command's errors are instances of ActiveModel::Errors (the same error objects that ActiveRecord uses)
* You can add ActiveModel::Validations to validate the input to your command. These validations are run before the command's result is generated and the result is only generated when they are valid.
* ActiveModel::Commands have an `authorized?` hook which is useful when calling commands outside of controller.
* ActiveModel::Commands have a `noop?` hook which for the command is demeed successful but should't make any changes. This is useful when your command is creating events as part of event sourcing.
* In many instances a command's result will be an instance of ActiveModel or ActiveRecord. If that result has errors, those errors will be merged with the commands errors.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_model_command'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_model_command


Include a default error message for unauthorized commands in our locale file (e.g. config/locales/en.yml)

```yaml
en:
  activemodel:
    errors:
      messages:
        unauthorized: "not allowed"
```

## Usage

A bare minimum example:

```ruby
class DoubleItCommand
  prepend ActiveModel::Command

  attr_accessor :x

  def call
    x * 2
  end
end

command = DoubleItCommand.new(x: 9)
command.call
command.result #=> 18
command.success? #=> true
```

A complete overview

```ruby
class AuthenticateUser
  prepend ActiveModel::Command

  # Declare your attributes or define your own initialize method
  attr_accessor :ip, :name, :password, :remember_me

  # Declare your validations (optional)
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true

  # Declare an after_initialize (optional)
  def after_initialize
    @remember_me ||= false
  end
  
  # Declare an authorized? (optional)
  def authorized?
    authorized_ip?(ip)
  end

  # Declare a possible noop? The command will be successful but never call #call
  def noop?
    ...
  end

  # The required #call method defines your result
  def call
    if user && user.validate_password?(password)
      user.generate_token(remember_me)
    else
      errors.add(:base, message: "email address or password incorrect")
      nil
    end
  end

  private
  
  def user
    @user ||= User.find_by(email: email)
  end

  def authorized_ip?
    ...
  end
end

command = AuthenticateUser.new(email: nil, password: "password123")
command.call #=> command; note the call method is never run because the command is invalid
command.errors.full_messages #=> {email: ["Email is blank"] }
```

And a more sophisticated example with `authorized?` method.

```ruby
class DeletePostCommand
  prepend ActiveModel::Command

  attr_accessor :post

  def authorized?
    post.owner == current_user
  end

  def call
    post.destroy
  end
end

command = DeletePostCommand.call(post: post, current_user: not_post_owner)
command.success? #=> false
command.errors.full_messages #=> { base: ["not allowed"] }
```

And another that will bubble up errors from the result

```ruby
class Post < ActiveRecord::Base
  validates :content, presence: true
end

class CreatePostCommand
  prepend ActiveModel::Command

  attr_accessor :content

  def call
    Post.create(content: content)
  end
end

command = CreatePostCommand.call(content: content)
command.success? #=> false
command.errors.full_messages #=> {email: ["Content is blank"] }
```

Use `after_initialize` to set default.

```ruby
class CreatePostCommand
  prepend ActiveModel::Command

  attr_accessor :content

  after_initialize
    @content ||= "No content"
  end

  def call
    Post.create(content: content)
  end
end
```

For event sourcing, there's a `noop?` method.

```ruby
class UpdatePost
  prepend ActiveModel::Command

  attr_accessor :post, :content

  def noop?
    post.content == content
  end

  def call
    build_event
  end
end
```

You can also just include your own initializer similiar to SimpleCommand:

```ruby
class CreatePostCommand
  prepend ActiveModel::Command

  def initialize(content)
    @content = content
  end

  def call
    Post.create(content: @content)
  end
end
```

### Composite Commands

Composite commands are commands that can run subcommands which, upon failure or exception, halt execution and fail the composite command. Subcommands may be other composite commands.

```ruby
class TestCommand
  prepend ActiveModel::Command

  def initialize(on_call)
    @on_call = on_call
  end

  def call
    case @on_call
    when :raise
      raise RuntimeError
    when :success
      return :success
    else :failure
      errors.add(:base, :failure)
    end
  end
end

class CompositeCommand
  prepend ActiveModel::CompositeCommand
  attr_reader :subcommands

  validates :subcommands, presence: true

  def initialize(subcommands)
    @subcommands = subcommands
  end

  def call
    subcommands.each do |subcommand|
      call_subcommand subcommand
    end

    :result
  end
end

success_composite = CompositeCommand.call([TestCommand.new(:success)])
success_composite.success? # => true
success_composite.result # => :result

failure_composite = CompositeCommand.call([TestCommand.new(:failure)])
failure_composite.success? # => false
failure_composite.errors.details # => {:base=>[{:error=>:failure}]}

deep_failure_composite = CompositeCommand.call([CompositeCommand.new([TestCommand.new(:failure)])])
deep_failure_composite.success? # => false
deep_failure_composite.errors.details # => {:base=>[{:error=>:failure}]}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/goldstar/active_model_command. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveModelCommand project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/goldstar/active_model_command/blob/master/CODE_OF_CONDUCT.md).
