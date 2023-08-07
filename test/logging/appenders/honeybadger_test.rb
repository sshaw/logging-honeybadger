# coding: utf-8
require "minitest/autorun"

# Without this the tests fail, see:
# https://github.com/honeybadger-io/honeybadger-ruby/issues/485
ENV["HONEYBADGER_SEND_DATA_AT_EXIT"] = "false"

require "logger"
require "logging"

class StackLogger
  Error = Class.new(StandardError)

  @@log = Logging.logger[self]
  @@log.add_appenders(Logging::Appenders::Honeybadger.new)

  class << self
    def string
      foo("stackin' and mackin'")
    end

    def error
      raise Error, "classy", %w[a b c]
    rescue => e
      @@log.error(e)
    end

    private

    def foo(error)
      bar(error)
    end

    def bar(error)
      @@log.error(error)
    end
  end
end

class TestAppender < Minitest::Test
  def setup
    Honeybadger.configure do |config|
      config.backend = "test"
      config.api_key = "9999"
      config.root = Dir.pwd
      config.logger = Logger.new(File::NULL)
    end

    sent_notices.clear
  end

  def test_new_appender_without_args
    app = Logging::Appenders::Honeybadger.new

    assert_equal app.name, "honeybadger"
    assert_same app, Logging::Appenders["honeybadger"]

    assert_equal "9999", Honeybadger.config[:api_key]
    assert_equal Dir.pwd, Honeybadger.config[:root]
  end

  def test_new_appender_without_name
    app = Logging::Appenders::Honeybadger.new(config)

    assert_equal app.name, "honeybadger"
    assert_same app, Logging::Appenders["honeybadger"]

    assert_equal "X123", Honeybadger.config[:api_key]
    assert_equal "foo", Honeybadger.config[:root]
    assert_includes Honeybadger.config[:"exceptions.ignore"], "A", "B"
  end

  def test_new_appender_with_name
    app = Logging::Appenders::Honeybadger.new("sshaw", config)

    assert_equal app.name, "sshaw"
    assert_same app, Logging::Appenders["sshaw"]

    assert_equal "X123", Honeybadger.config[:api_key]
    assert_equal "foo", Honeybadger.config[:root]
    assert_includes Honeybadger.config[:"exceptions.ignore"], "A", "B"
  end

  def test_appender_class_method_without_args
    app = Logging.appenders.honeybadger

    assert_equal app.name, "honeybadger"
    assert_same app, Logging::Appenders["honeybadger"]

    assert_equal "9999", Honeybadger.config[:api_key]
    assert_equal Dir.pwd, Honeybadger.config[:root]
  end

  def test_appender_class_method_with_name
    app = Logging.appenders.honeybadger("sshaw", config)

    assert_equal app.name, "sshaw"
    assert_same app, Logging::Appenders["sshaw"]

    assert_equal "X123", Honeybadger.config[:api_key]
    assert_equal "foo", Honeybadger.config[:root]
    assert_includes Honeybadger.config[:"exceptions.ignore"], "A", "B"
  end

  def test_appender_class_method_without_name
    app = Logging.appenders.honeybadger(config)

    assert_equal app.name, "honeybadger"
    assert_same app, Logging::Appenders["honeybadger"]

    assert_equal "X123", Honeybadger.config[:api_key]
    assert_equal "foo", Honeybadger.config[:root]
    assert_includes Honeybadger.config[:"exceptions.ignore"], "A", "B"
  end

  def test_only_error_level_logged
    log = Logging.logger[__method__]
    log.add_appenders(Logging::Appenders::Honeybadger.new(config))

    log.info("Hi")
    log.error("¡Hola!")
    log.debug("Oizinho")
    log.warn("Perigo")
    log.error("Hello hello!")

    Honeybadger.flush

    assert_equal 2, sent_notices.size
    assert_equal "¡Hola!", sent_notices[0].error_message
    assert_equal "Hello hello!", sent_notices[1].error_message
  end

  def test_log_string_error_backtrace_does_not_include_appender
    StackLogger.string
    Honeybadger.flush

    assert_equal 1, sent_notices.size

    backtrace = sent_notices[0].backtrace
    assert_match(/in `bar'/, backtrace[0])
    assert_match(/in `foo'/, backtrace[1])
    assert_match(/in `string'/, backtrace[2])
    assert_match(/in `test_/, backtrace[3])  # ` This is comment for emacs highlighting
  end

  def test_log_exception_backtrace_uses_exceptions_backtrace
    StackLogger.error
    Honeybadger.flush

    assert_equal 1, sent_notices.size
    assert_equal %w[a b c], sent_notices[0].backtrace
  end

  def test_log_context_added_to_honebadger_context
    log = Logging.logger[__method__]
    log.add_appenders(Logging::Appenders::Honeybadger.new(config))

    Logging.mdc["foo"] = 123
    Logging.mdc["bar"] = "sshaw"

    log.error "con;text"

    Honeybadger.flush

    assert_equal 1, sent_notices.size

    context = { "foo" => 123, "bar" => "sshaw" }
    assert_equal "con;text", sent_notices[0].error_message
    assert_equal context, sent_notices[0].context
  end

  def test_errors_as_honeybadger_logger_ignored
    log = Logging.logger[__method__]
    # api_key => nil will cause Honeybadger to log an error on notify
    log.add_appenders(Logging::Appenders::Honeybadger.new(:api_key => nil))

    Honeybadger.configure { |cfg| cfg.logger = log }

    log.info("info")
    # If the test fails this will trigger a SystemStackError
    log.error("some error")
  end

  private

  def config
    {
      :api_key => "X123",
      :root => "foo",
      :backend => "test",
      :exceptions => { :ignore  => %w[A B] }
    }
  end

  def sent_notices
    Honeybadger::Backend::Test.notifications[:notices]
  end
end
