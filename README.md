# Logging::Appenders::Honeybadger

Honeybadger appender for [the Logging gem](https://github.com/TwP/logging)

## Overview

```rb
require "logging"
require "logging/appenders/honeybadger"

log = Logging.logger[self]
log.add_appenders(
  Logging.appenders.honeybadger(
    :api_key => "123XYZ",
    :exceptions => { :ignore => %w[SomeThang AnotherThang] }
  )
)

# Or

Honeybadger.configure do |cfg|
  # ...
end

log.add_appenders(Logging.appenders.honeybadger)

log.info  "Not sent to honeybadger"
log.error "Honeybadger here I come!"
log.error SomeError.new("See you @ app.honeybadger.io!")
```

## Description

Only events with the `:error` log level are sent to Honeybadger.
By default the appender  will be named `"honeybadger"`. This can be changed by passing a name
to the `honeybadger` method:

    Logging.appenders.honeybadger("another_name", options)

Honeybadger configuration can be done via `Honeybadger.configure` or via `Logging.appenders.honeybadger`.

## See Also

[`Logging::Appenders::Airbrake`](https://github.com/sshaw/logging-appenders-airbrake) - Airbrake appender for the Logging gem

## Author

Skye Shaw [sshaw AT gmail.com]

## License

Released under the MIT License: www.opensource.org/licenses/MIT
