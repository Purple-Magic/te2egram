#!/usr/bin/env ruby

require 'sinatra'
require 'yaml'
require 'erb'
require 'json'
require_relative './define_steps'

# Load steps configuration from YAML file
CONFIG = YAML.safe_load(ERB.new(File.read('steps.yml')).result, permitted_classes: [Time])

$update_call_count = 0 # Counter to track /getUpdates calls
$messages = [] # Store sent messages for mocking

# Endpoint to set a webhook (mocked)
post %r{/bot(.+)/setWebhook} do
  content_type :json
  status 200
  { ok: true, result: true }.to_json
end

# Endpoint to delete a webhook (mocked)
post %r{/bot(.+)/deleteWebhook} do
  content_type :json
  status 200
  { ok: true, result: true }.to_json
end

# Endpoint to get updates (mocked)
# post %r{/bot(.+)/getUpdates} do
post '/bot1/getUpdates' do
  content_type :json
  status 200

  # Increment the call count
  $update_call_count += 1

  puts "Step: #{$update_call_count}"

  # Fetch updates based on the step configuration
  step = CONFIG['steps'].find { |s| s['id'] == $update_call_count }
  updates = step ? step['updates'] : []

  { ok: true, result: updates }.to_json
end

# Endpoint to send a message (mocked)
post %r{/bot(.+)/sendMessage} do
  content_type :json
  request_payload = JSON.parse(request.body.read)

  chat_id = request_payload['chat_id']
  text = request_payload['text']

  # Create a mock message object
  message = {
    message_id: $messages.size + 1,
    chat: {
      id: chat_id,
      type: "private"
    },
    date: Time.now.to_i,
    text: text
  }

  # Save the message to the in-memory storage
  $messages << message

  # Respond with the mocked message object
  { ok: true, result: message }.to_json
end

# Endpoint to reset server state
post '/reset' do
  content_type :json
  $update_call_count = 0 # Reset call count
  $messages.clear # Clear stored messages
  { ok: true, message: 'Server reset' }.to_json
end

# Endpoint to get bot information (getMe)
post %r{/bot(.+)/getMe} do
  content_type :json
  status 200
  {
    ok: true,
    result: {
      id: 123456789,
      is_bot: true,
      first_name: "TestBot",
      username: "Test_Bot",
      can_join_groups: true,
      can_read_all_group_messages: true,
      supports_inline_queries: true
    }
  }.to_json
end

# Handle unsupported endpoints gracefully
not_found do
  content_type :json
  status 404
  {
    ok: false,
    error_code: 404,
    description: "Not Found"
  }.to_json
end

set :protection, except: :host
set :bind, '0.0.0.0'

# Explicitly start the Sinatra application
Sinatra::Application.run! if __FILE__ == $PROGRAM_NAME
