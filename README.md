# ActiveModel::Command

ActiveModel::Command is a way to add CQRS-style service objects to your project. It was inspired by and is based on [SimpleCommand](https://github.com/nebulab/simple_command) gem with a similar interface. Whereas SimpleCommand has no dependencies and plays well with ActiveModel, ActiveModel::Command does specifically require ActiveModel.

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

```
en:
  activemodel:
    errors:
      messages:
        unauthorized: "not allowed"
```

## Usage

In it's simplest form:

```
class DoubleItCommand
  prepend ActiveModel::Command

  attr_accessor :x

  def call
    x * 2
  end
end

command = DoubleItCommand.new(9)
command.call
command.result #=> 18
command.success? #=> true
```

Here's an example with some validations:

```
class AuthenticateUser
  prepend ActiveModel::Command

  attr_accessor :email, :password

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true

  def call
    if user&.validate_password?(password)
      user
    else
      errors.add(:base, message: "email address or password incorrect")
      nil
    end
  end

  private

  def user
    @user ||= User.find_by(email: email)
  end
end

command = AuthenticateUser.new(email: nil, password: "password123")
command.call #=> command; note the call method is never run because the command is invalid
command.errors.full_messages #=> {email: ["Email is blank"] }
```

And a more sophisticated example with `authorized?` method.

```
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

```
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

command = CreatePostCommand.call(content)
command.success? #=> false
command.errors.full_messages #=> {email: ["Content is blank"] }
```

Use `after_initialize` to set default.

```
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

```
class updatePost
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

```
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


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/goldstar/active_model_command. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveModelCommand project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/goldstar/active_model_command/blob/master/CODE_OF_CONDUCT.md).
