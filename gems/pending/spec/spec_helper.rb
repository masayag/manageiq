require_relative '../bundler_setup'

if ENV["TRAVIS"]
  require 'coveralls'
  Coveralls.wear_merged! { add_filter("/spec/") }
end

# Push the gems/pending directory onto the load path
GEMS_PENDING_ROOT ||= File.expand_path(File.join(__dir__, ".."))
$LOAD_PATH << GEMS_PENDING_ROOT

# Initialize the global logger that might be expected
require 'logger'
$log ||= Logger.new("/dev/null")

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[File.expand_path(File.join(__dir__, 'support/**/*.rb'))].each { |f| require f }

RSpec.configure do |config|
  config.after(:each) do
    Module.clear_all_cache_with_timeout if Module.respond_to?(:clear_all_cache_with_timeout)
  end

  if ENV["TRAVIS"]
    config.after(:suite) do
      require "spec/coverage_helper.rb"
    end
  end

  config.backtrace_exclusion_patterns -= [%r{/lib\d*/ruby/}, %r{/gems/}]
  config.backtrace_exclusion_patterns << %r{/lib\d*/ruby/[0-9]}
  config.backtrace_exclusion_patterns << %r{/gems/[0-9][^/]+/gems/}
end
