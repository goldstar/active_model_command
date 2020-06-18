require "bundler/setup"
require "active_model/command"
require "active_model/composite_command"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

Dir[File.join(File.dirname(__FILE__), 'examples', '**/*.rb')].each do |factory|
  require factory
end
