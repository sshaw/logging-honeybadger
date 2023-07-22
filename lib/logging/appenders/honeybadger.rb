# frozen_string_literal: true

require "honeybadger"
require "logging"

module Logging
  module Appenders
    def self.honeybadger(*args)
      if args.empty?
        return self["honeybadger"] || Logging::Appenders::Honeybadger.new
      end

      Logging::Appenders::Honeybadger.new(*args)
    end

    class Honeybadger < Logging::Appender
      VERSION = "0.0.1"

      # Remove calls to this class in the stacktrace sent to Honeybadger.
      # Only used when logging a String message.
      HONEYBADGER_BT_FILTER = %r{/logging-[^/]+/lib/logging/}

      # Can't use respond_to?: https://github.com/honeybadger-io/honeybadger-ruby/issues/481
      HONEYBADGER_SIMPLE_OPTIONS = %i[
      api_key
      env
      report_data
      root
      revision
      hostname
      backend
      debug
      send_data_at_exit
      max_queue_size
      config_path
      development_environments
      plugins
      skipped_plugins
    ].freeze

      HONEYBADGER_NESTED_OPTIONS = %i[
      breadcrumbs
      connection
      delayed_job
      exceptions
      logging
      rails
      request
      sidekiq
    ].freeze

      HONEYBADGER_OPTIONS = (HONEYBADGER_SIMPLE_OPTIONS + HONEYBADGER_NESTED_OPTIONS).freeze

      def initialize(*args)
        args.compact!

        appender = { :level => :error }

        name = args.first.is_a?(String) ? args.shift : "honeybadger"
        honeybadger = args.last.is_a?(Hash) ? args.pop.dup : {}

        ::Honeybadger.configure do |cfg|
          honeybadger.keys.each do |name|
            if HONEYBADGER_OPTIONS.include?(name)
              set_honeybadger_option(cfg, name, honeybadger[name])
            else
              appender[name] = honeybadger.delete(name)
            end
          end
        end

        super(name, appender)
      end

      private

      def set_honeybadger_option(cfg, name, value)
        if HONEYBADGER_SIMPLE_OPTIONS.include?(name)
          cfg.public_send("#{name}=", value)
          return
        end

        raise ArgumentError, "Nested option #{name}'s value must be a Hash, got #{value.class}" unless value.is_a?(Hash)

        obj = cfg.public_send(name)
        value.each do |method, v|
          setter = "#{method}="
          if obj.public_send(method).is_a?(Array)
            obj.public_send(setter, obj.public_send(method) + Array(v))
          else
            obj.public_send(setter, v)
          end
        end
      end

      def write(event)
        # FIXME: if the Honeybadger logger is this we must avoid loop
        #return self if caller.any? { |bt| bt =~ INTERNAL_BT_FILTER }

        # Docs say event can be a String too, not sure when/how but we'll check anyways
        error = event.is_a?(Logging::LogEvent) ? event.data : event

        options = {}
        options[:context] = Logging.mdc.context if Logging.mdc.context.any?

        if error.is_a?(Exception)
          options[:backtrace] = error.backtrace
        else
          options[:backtrace] = caller.reject { |line| line =~ HONEYBADGER_BT_FILTER }
        end

        ::Honeybadger.notify(error, options)
      end
    end
  end
end
