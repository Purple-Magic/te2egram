#!/usr/bin/env ruby

require 'sinatra'
require 'yaml'
require 'erb'
require 'json'
require 'logger'
require_relative './define_steps'

# Initialize logger
logger = Logger.new($stdout)
logger.level = Logger::DEBUG

# Sinatra configuration
configure do
  set :protection, except: [:host]
  set :logger, logger
  set :bind, 'te2egram'
  set :environment, :test

  logger.info "Middleware stack: #{Sinatra::Base.middleware.inspect}"
end

# Load steps configuration
begin
  CONFIG = YAML.safe_load(ERB.new(File.read('steps.yml')).result, permitted_classes: [Time])
  settings.logger.info('Configuration loaded from steps.yml')
rescue StandardError => e
  settings.logger.error("Failed to load configuration: #{e.message}")
  exit 1
end

# Global variables
$update_call_count = 0
$messages = []

# Log requests
before do
  settings.logger.info("Request received: #{request.request_method} #{request.path}")
  settings.logger.info("Host header: #{request.env['HTTP_HOST']}")
end

# Routes
get '/' do
  settings.logger.info('Health check endpoint accessed')
  content_type :json
  { ok: true, message: 'Healthy!' }.to_json
end

post %r{/bot(.+)/setWebhook} do
  settings.logger.info('setWebhook endpoint called')
  content_type :json
  { ok: true, result: true }.to_json
end

post %r{/bot(.+)/deleteWebhook} do
  settings.logger.info('deleteWebhook endpoint called')
  content_type :json
  { ok: true, result: true }.to_json
end

post '/bot1/getUpdates' do
  settings.logger.info('getUpdates endpoint called')
  content_type :json

  $update_call_count += 1
  settings.logger.info("Step count: #{$update_call_count}")

  step = CONFIG['steps'].find { |s| s['id'] == $update_call_count }
  updates = step ? step['updates'] : []

  if updates.empty?
    settings.logger.warn('No updates found for this step')

    status 204
  else
    settings.logger.debug("Updates for step: #{updates}")
  end

  { ok: true, result: updates }.to_json
end

post %r{/bot(.+)/sendMessage} do
  settings.logger.info('sendMessage endpoint called')
  content_type :json

  payload = JSON.parse(request.body.read)
  chat_id = payload['chat_id']
  text = payload['text']
  settings.logger.info("Message received - Chat ID: #{chat_id}, Text: #{text}")

  message = {
    message_id: $messages.size + 1,
    chat: {
      id: chat_id,
      type: "private"
    },
    date: Time.now.to_i,
    text: text
  }

  $messages << message
  settings.logger.info("Message stored: #{message}")

  { ok: true, result: message }.to_json
end

post '/reset' do
  settings.logger.info('Reset endpoint called')
  content_type :json

  $update_call_count = 0
  $messages.clear
  settings.logger.info('Server state reset')

  { ok: true, message: 'Server reset' }.to_json
end

post %r{/bot(.+)/getMe} do
  settings.logger.info('getMe endpoint called')
  content_type :json

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
  settings.logger.warn("Unsupported endpoint accessed: #{request.path}")
  content_type :json
  { ok: false, error_code: 404, description: 'Not Found' }.to_json
end

# Start Sinatra application
Sinatra::Application.run! if __FILE__ == $PROGRAM_NAME
