# ConektaEvent
[![Dependency Status](https://gemnasium.com/moneypool/conekta_event.svg)](https://gemnasium.com/moneypool/conekta_event) [![Code Climate](https://codeclimate.com/github/moneypool/conekta_event/badges/gpa.svg)](https://codeclimate.com/github/moneypool/conekta_event) [![Test Coverage](https://codeclimate.com/github/moneypool/conekta_event/badges/coverage.svg)](https://codeclimate.com/github/moneypool/conekta_event/coverage)

ConektaEvent is based on [StripeEvent](https://github.com/integrallis/stripe_event) by [Integrallis](http://integrallis.com/) built on the [ActiveSupport::Notifications API](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html). Incoming webhook requests are authenticated by [retrieving the event object](https://www.conekta.io/es/docs/api?language=curl&vertical=productos-digitales#eventos) from Conekta. Define subscribers to handle specific event types. Subscribers can be a block or an object that responds to `#call`.

## Install

```ruby
# Gemfile
gem 'conekta_event'
```

```ruby
# config/routes.rb
mount ConektaEvent::Engine, at: '/my-chosen-path' # provide a custom path
```

## Usage

```ruby
# config/initializers/conekta.rb
Conekta.api_key = ENV['CONEKTA_SECRET_KEY'] # e.g. sk_live_1234

ConektaEvent.configure do |events|
  events.subscribe 'charge.paid' do |event|
    # Define subscriber behavior based on the event object
    event.class       #=> Conekta::Event
    event.type        #=> "charge.paid"
    event.data.object #=> #<Conekta::Charge:0x3fcb34c115f8>
  end

  events.all do |event|
    # Handle all event types - logging, etc.
  end
end
```

### Subscriber objects that respond to #call

```ruby
class CustomerCreated
  def call(event)
    # Event handling
  end
end

class BillingEventLogger
  def initialize(logger)
    @logger = logger
  end

  def call(event)
    @logger.info "BILLING:#{event.type}:#{event.id}"
  end
end
```

```ruby
ConektaEvent.configure do |events|
  events.all BillingEventLogger.new(Rails.logger)
  events.subscribe 'customer.created', CustomerCreated.new
end
```

### Subscribing to a namespace of event types

```ruby
ConektaEvent.subscribe 'subscription.' do |event|
  # Will be triggered for any subscription.* events
end
```

<!-- ## Securing your webhook endpoint

ConektaEvent automatically fetches events from Conekta to ensure they haven't been forged. However, that doesn't prevent an attacker who knows your endpoint name and an event's ID from forcing your server to process a legitimate event twice. If that event triggers some useful action, like generating a license key or enabling a delinquent account, you could end up giving something the attacker is supposed to pay for away for free.

To prevent this, ConektaEvent supports using HTTP Basic authentication on your webhook endpoint. If only Conekta knows the basic authentication password, this ensures that the request really comes from Conekta. Here's what you do:

1. Arrange for a secret key to be available in your application's environment variables or `secrets.yml` file. You can generate a suitable secret with the `rake secret` command. (Remember, the `secrets.yml` file shouldn't contain production secrets directly; it should use ERB to include them.)

2. Configure ConektaEvent to require that secret be used as a basic authentication password, using code along the lines of these examples:

    ```ruby
    # CONEKTA_WEBHOOK_SECRET environment variable
    ConektaEvent.authentication_secret = ENV['CONEKTA_WEBHOOK_SECRET']
    # conekta_webhook_secret key in secrets.yml file
    ConektaEvent.authentication_secret = Rails.application.secrets.stripe_webhook_secret
    ```

3. When you specify your webhook's URL in Conekta's settings, include the secret as a password in the URL, along with any username:

        https://conekta:my-secret-key@myapplication.com/my-webhook-path

This is only truly secure if your webhook endpoint is accessed over SSL, which Conekta strongly recommends anyway.
-->
<!--
## Configuration

If you have built an application that has multiple Conekta accounts--say, each of your customers has their own--you may want to define your own way of retrieving events from Conekta (e.g. perhaps you want to use the [user_id parameter](https://conekta.com/docs/apps/getting-started#webhooks) from the top level to detect the customer for the event, then grab their specific API key). You can do this:

```ruby
ConektaEvent.event_retriever = lambda do |params|
  api_key = Account.find_by!(conekta_user_id: params[:user_id]).api_key
  Conekta::Event.find(params[:id], api_key)
end
```

```ruby
class EventRetriever
  def call(params)
    api_key = retrieve_api_key(params[:user_id])
    Conekta::Event.find(params[:id], api_key)
  end

  def retrieve_api_key(stripe_user_id)
    Account.find_by!(conekta_user_id: conekta_user_id).api_key
  rescue ActiveRecord::RecordNotFound
    # whoops something went wrong - error handling
  end
end

ConektaEvent.event_retriever = EventRetriever.new
```

If you'd like to ignore particular webhook events (perhaps to ignore test webhooks in production, or to ignore webhooks for a non-paying customer), you can do so by returning `nil` in you custom `event_retriever`. For example:

```ruby
ConektaEvent.event_retriever = lambda do |params|
  return nil if Rails.env.production? && !params[:livemode]
  Conekta::Event.find(params[:id])
end
```

```ruby
ConektaEvent.event_retriever = lambda do |params|
  account = Account.find_by!(conekta_user_id: params[:user_id])
  return nil if account.delinquent?
  Conekta::Event.find(params[:id], account.api_key)
end
```
-->
## Without Rails

ConektaEvent can be used outside of Rails applications as well. Here is a basic Sinatra implementation:

```ruby
require 'json'
require 'sinatra'
require 'conekta_event'

Conekta.api_key = ENV['STRIPE_SECRET_KEY']

ConektaEvent.subscribe 'charge.paid' do |event|
  # Look ma, no Rails!
end

post '/_billing_events' do
  data = JSON.parse(request.body.read, symbolize_names: true)
  ConektaEvent.instrument(data)
  200
end
```

## Testing

Handling webhooks is a critical piece of modern billing systems. Verifying the behavior of ConektaEvent subscribers can be done fairly easily by stubbing out the HTTP request used to authenticate the webhook request. Tools like [Webmock](https://github.com/bblimke/webmock) and [VCR](https://github.com/vcr/vcr) work well. [RequestBin](http://requestb.in/) is great for collecting the payloads. For exploratory phases of development, [UltraHook](http://www.ultrahook.com/) and other tools can forward webhook requests directly to localhost. A quick look:

```ruby
# spec/requests/billing_events_spec.rb
require 'spec_helper'

describe "Billing Events" do
  def stub_event(fixture_id, status = 200)
    stub_request(:get, "https://api.conekta.io/events/#{fixture_id}").
      to_return(status: status, body: File.read("spec/support/fixtures/#{fixture_id}.json"))
  end

  describe "charge.paid" do
    before do
      stub_event 'evt_customer_created'
    end

    it "is successful" do
      post '/_billing_events', id: 'evt_customer_created'
      expect(response.code).to eq "200"
      # Additional expectations...
    end
  end
end
```
### Versioning

Semantic Versioning 2.0 as defined at <http://semver.org>.

### License

[MIT License](https://github.com/integrallis/stripe_event/blob/master/LICENSE.md).
Copyright 2015 Moneypool SAPI de CV.
