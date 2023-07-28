# frozen_string_literal: true

module Logging
  module Plugins
    module Honeybadger
      def self.initialize_honeybadger
        require File.expand_path("../../appenders/honeybadger", __FILE__)
      end
    end
  end
end
