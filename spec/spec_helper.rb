if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }
Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.include Spec::Support::ApiRequestHelpers, :type => :request

  config.before(:each, :type => :request) { init_api }
end

require "cfme-cloud_services"
