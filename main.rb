#!/usr/bin/env ruby

require 'sinatra'
require 'json'

# Data storage for the emulated Telegram API
$updates = []
$chats = {}
$messages = []

# Endpoint to set a webhook (mocked)
post '/bot:token/setWebhook' do
  content_type :json
  { ok: true, result: true }.to_json
end

# Endpoint to get updates (mocked)
get '/bot:token/getUpdates' do
  content_type :json
  { ok: true, result: $updates }.to_json
end

# Endpoint to send a message (mocked)
post '/bot:token/sendMessage' do
  content_type :json
  request_payload = JSON.parse(request.body.read)

  chat_id = request_payload['chat_id']
  text = request_payload['text']

  # Save the message in the emulated chat
  message = {
    message_id: $messages.size + 1,
    chat: { id: chat_id, type: 'private' },
    date: Time.now.to_i,
    text: text
  }
  $messages << message

  # Mocked response
  { ok: true, result: message }.to_json
end

# Endpoint to emulate receiving updates from Telegram (mocked)
post '/receiveUpdate' do
  content_type :json
  request_payload = JSON.parse(request.body.read)

  update_id = $updates.size + 1
  $updates << {
    update_id: update_id,
    message: request_payload['message']
  }

  { ok: true, update_id: update_id }.to_json
end

# Utility endpoints for testing
post '/reset' do
  content_type :json
  $updates.clear
  $messages.clear
  $chats.clear
  { ok: true, message: 'Server reset' }.to_json
end

get '/messages' do
  content_type :json
  { ok: true, result: $messages }.to_json
end

# Explicitly start the Sinatra application
Sinatra::Application.run! if __FILE__ == $PROGRAM_NAME
