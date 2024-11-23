#!/usr/bin/env ruby

require 'sinatra'
require 'json'

# Data storage for the emulated Telegram API
$updates = [
  {
    update_id: 1,
    message: {
      message_id: 1,
      from: {
        id: 123456789,
        is_bot: false,
        first_name: "TestUser",
        username: "test_user",
        language_code: "en"
      },
      chat: {
        id: 123456789,
        first_name: "TestUser",
        username: "test_user",
        type: "private"
      },
      date: Time.now.to_i,
      text: "/start"
    }
  }
]
$chats = {}
$messages = []
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

  case $update_call_count
  when 1
    { ok: true, result: $updates }.to_json
  when 2
    {
      ok: true,
      result: [
        {
          update_id: 2,
          message: {
            message_id: 2,
            from: {
              id: 123456789,
              is_bot: false,
              first_name: "TestUser",
              username: "test_user",
              language_code: "en"
            },
            chat: {
              id: 123456789,
              first_name: "TestUser",
              username: "test_user",
              type: "private"
            },
            date: Time.now.to_i,
            text: "/start2"
          }
        }
      ]
    }.to_json
  else
    { ok: true, result: [] }.to_json
  end
end

# Endpoint to send a message (mocked)
post %r{/bot(.+)/sendMessage} do
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

# Endpoint to reset server state
post '/reset' do
  content_type :json
  $updates.clear
  $messages.clear
  $chats.clear
  $update_call_count = 0 # Reset call count

  # Add the /start message back to updates
  $updates << {
    update_id: 1,
    message: {
      message_id: 1,
      from: {
        id: 123456789,
        is_bot: false,
        first_name: "TestUser",
        username: "test_user",
        language_code: "en"
      },
      chat: {
        id: 123456789,
        first_name: "TestUser",
        username: "test_user",
        type: "private"
      },
      date: Time.now.to_i,
      text: "/start"
    }
  }

  { ok: true, message: 'Server reset and /start message added' }.to_json
end

# Endpoint to fetch all messages
get '/messages' do
  content_type :json
  { ok: true, result: $messages }.to_json
end

# Endpoint to handle "getMe"
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

# Explicitly start the Sinatra application
Sinatra::Application.run! if __FILE__ == $PROGRAM_NAME
