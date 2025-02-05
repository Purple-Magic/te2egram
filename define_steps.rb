#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'
require 'active_support/core_ext/hash'

class StepContext
  def initialize(updates)
    @updates = updates
  end

  def update(update_id:, text:, chat_id: 123456789, username: 'test_user', first_name: 'TestUser')
    @updates << {
      update_id: update_id,
      message: {
        message_id: update_id,
        from: {
          id: chat_id,
          is_bot: false,
          first_name: first_name,
          username: username,
          language_code: 'en'
        },
        chat: {
          id: chat_id,
          first_name: first_name,
          username: username,
          type: 'private'
        },
        date: Time.now.to_i,
        text: text
      }
    }
  end
end

class StepBuilder
  attr_reader :steps

  def initialize
    @steps = []
  end

  def step(id:, &block)
    current_step = { id: id, updates: [] }
    StepContext.new(current_step[:updates]).instance_eval(&block)
    @steps << current_step
  end

  def to_yaml
    { 'steps' => @steps.map(&:deep_stringify_keys) }.to_yaml
  end
end

# DSL Interface to Define Steps
def define_steps(&block)
  builder = StepBuilder.new
  builder.instance_eval(&block)
  builder
end

# File path for the YAML configuration
steps_file_path = 'steps.yml'

# Define steps using the DSL
steps = define_steps do
  step(id: 1) do
    update(update_id: 1, text: '/start')
  end

  step(id: 2) do
    update(update_id: 2, text: '/start2')
  end

  # step(id: 3) do
  #   # No updates for this step
  # end

  # step(id: 4) do
  #   update(update_id: 4, text: '/invited')
  # end

  # step(id: 5) do
  #   update(update_id: 5, text: '/reminder')
  # end

  # step(id: 6) do
  #   update(update_id: 6, text: '/share')
  # end

  # step(id: 7) do
  #   update(update_id: 7, text: '/about')
  # end

  # step(id: 8) do
  #   update(update_id: 8, text: '/support')
  # end

  # step(id: 9) do
  #   update(update_id: 9, text: 'UnhandledCommand')
  # end

  # step(id: 10) do
  #   update(update_id: 10, text: '/timezone_other')
  # end

  # step(id: 11) do
  #   update(update_id: 11, text: '/timezone_utc+3')
  # end
end

# Write steps to the YAML file
File.write(steps_file_path, steps.to_yaml)
puts "Steps have been written to #{steps_file_path}"
