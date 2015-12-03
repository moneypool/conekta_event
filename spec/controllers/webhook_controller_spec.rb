require 'rails_helper'
require 'spec_helper'

describe ConektaEvent::WebhookController, type: :controller do
  routes do
    ConektaEvent::Engine.routes
  end

  # def stub_event(identifier, status = 200)
  #   fixture_json = File.read("spec/support/fixtures/#{identifier}.json")
  #
  #   stub_request(:get, "https://api.conekta.io/events/#{identifier}").
  #     to_return(status: status, body: fixture_json)
  # end

  def webhook(params)
    post :event, params
  end

  it "succeeds with valid event data" do
    count = 0
    ConektaEvent.subscribe('charge.paid') { |evt| count += 1 }
    # stub_event('evt_charge_succeeded')

    webhook id: "5658c24aa1c0a620a200074e"

    expect(response.code).to eq '200'
    expect(count).to eq 1
  end

  it "succeeds when the event_retriever returns nil (simulating an ignored webhook event)" do
    count = 0
    ConektaEvent.event_retriever = lambda { |params| return nil }
    ConektaEvent.subscribe('charge.chargeback.won') { |evt| count += 1 }
    # stub_event('evt_charge_succeeded')

    webhook id: '5658c24aa1c0a620a200074e'

    expect(response.code).to eq '200'
    expect(count).to eq 0
  end

  it "denies access with invalid event data" do
    count = 0
    ConektaEvent.subscribe('charge.paid') { |evt| count += 1 }
    # stub_event('evt_invalid_id', 404)

    webhook id: 'evt_invalid_id'

    expect(response.code).to eq '401'
    expect(count).to eq 0
  end

  it "ensures user-generated Conekta exceptions pass through" do
    ConektaEvent.subscribe('charge.paid') { |evt| raise Conekta::Error, "testing" }
    # stub_event('evt_charge_succeeded')

    expect { webhook id: '5658c24aa1c0a620a200074e' }.to raise_error(Conekta::Error, /testing/)
  end

  # context "with an authentication secret" do
  #   def webhook_with_secret(secret, params)
  #     request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('user', secret)
  #     webhook params
  #   end
  #
  #   before(:each) { ConektaEvent.authentication_secret = "secret" }
  #   after(:each) { ConektaEvent.authentication_secret = nil }
  #
  #   it "rejects requests with no secret" do
  #     stub_event('evt_charge_succeeded')
  #
  #     webhook id: 'evt_charge_succeeded'
  #     expect(response.code).to eq '401'
  #   end
  #
  #   it "rejects requests with incorrect secret" do
  #     stub_event('evt_charge_succeeded')
  #
  #     webhook_with_secret 'incorrect', id: 'evt_charge_succeeded'
  #     expect(response.code).to eq '401'
  #   end
  #
  #   it "accepts requests with correct secret" do
  #     stub_event('evt_charge_succeeded')
  #
  #     webhook_with_secret 'secret', id: 'evt_charge_succeeded'
  #     expect(response.code).to eq '200'
  #   end
  # end
end
