if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

unless defined?(SPEC_HELPER_LOADED)
  SPEC_HELPER_LOADED = true

  require "yodlee_wrap"
  require 'dotenv'
  Dotenv.load

  YodleeWrap::Config.logger = Logger.new("log/test.log")
  YodleeWrap::Config.logger.level = Logger::DEBUG

  RSpec.configure do |config|
    config.filter_run :focus
    config.run_all_when_everything_filtered = true
  end
end
