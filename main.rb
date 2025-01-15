#!/usr/bin/env ruby

require 'sinatra'
require 'yaml'
require 'erb'
require 'json'
require 'logger'
require 'colorize'
require_relative './define_steps'

# Custom logger class with colorize integration
class ColoredLogger < Logger
  def format_message(severity, timestamp, progname, msg)
    color = case severity
            when 'DEBUG' then :blue
            when 'INFO' then :green
            when 'WARN' then :yellow
            when 'ERROR' then :red
            when 'FATAL' then :light_red
            else :default
            end

    formatted_msg = msg.gsub(/<([^>]+)>/, '\e[31m\\0\e[0m')

    "[#{timestamp.to_s.colorize(:light_cyan)}] " \
    "#{severity.ljust(5).colorize(color)} " \
    "#{formatted_msg.strip}\n"
  end
end

# Initialize logger
logger = ColoredLogger.new($stdout)
logger.level = Logger::DEBUG

# Sinatra configuration
configure do
  set :protection, except: [:host]
  set :logger, logger
  set :bind, 'te2egram'
  set :environment, :test

  logger.info "Middleware stack: #{Sinatra::Base.middleware.inspect}"
  logger.info "Host header: #{Socket.gethostname.colorize(:yellow)}"
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
  colored_path = request.path.colorize(:magenta)
  colored_method = request.request_method.colorize(:cyan)
  settings.logger.info("Request received")
  settings.logger.info("#{colored_method} #{colored_path}")
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

    $update_call_count = 0
    status 204
  else
    settings.logger.debug("Updates for step: #{updates}")
  end

  { ok: true, result: updates }.to_json
end

post '/bot1/sendMessage' do
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
  colored_path = request.path.colorize(:magenta)
  settings.logger.warn("Unsupported endpoint accessed: #{colored_path}")
  content_type :json
  { ok: false, error_code: 404, description: 'Not Found' }.to_json
end

# Start Sinatra application
Sinatra::Application.run! if __FILE__ == $PROGRAM_NAME
