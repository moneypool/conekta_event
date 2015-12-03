require 'coveralls'
Coveralls.wear!

require "conekta"
# require 'webmock/rspec'
require File.expand_path('../../lib/conekta_event', __FILE__)
Dir[File.expand_path('../spec/support/**/*.rb', __FILE__)].each { |f| require f }

RSpec.configure do |config|
  config.order = 'random'
  config.before(:all) { Conekta.api_key = 'key_Hmy6Q3emPzudSoddpxVE6w' }

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    @event_retriever = ConektaEvent.event_retriever
    @notifier = ConektaEvent.backend.notifier
    ConektaEvent.backend.notifier = @notifier.class.new
  end

  config.after do
    ConektaEvent.event_retriever = @event_retriever
    ConektaEvent.backend.notifier = @notifier
  end
end
