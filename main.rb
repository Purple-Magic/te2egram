#!/usr/bin/env ruby

require 'sinatra'
require 'yaml'
require 'erb'
require 'json'

# Load steps configuration from YAML file
CONFIG = YAML.safe_load(ERB.new(File.read('steps.yml')).result, permitted_classes: [Time])

$update_call_count = 0 # Counter to track /getUpdates calls

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
post %r{/bot(.+)/getUpdates} do
  content_type :json
  status 200

  # Increment the call count
  $update_call_count += 1

  # Fetch updates based on the step configuration
  step = CONFIG['steps'].find { |s| s['id'] == $update_call_count }
  updates = step ? step['updates'] : []

  { ok: true, result: updates }.to_json
end

# Endpoint to reset server state
post '/reset' do
  content_type :json
  $update_call_count = 0 # Reset call count
  { ok: true, message: 'Server reset' }.to_json
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

# Explicitly start the Sinatra application
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

Sinatra::Application.run! if __FILE__ == $PROGRAM_NAME

