require 'date'
require 'json'
require 'redis'

LED_BRIGHTNESS_PATH = "/sys/class/leds/led0/brightness"
LED_TRIGGER_PATH = "/sys/class/leds/led0/trigger"

LATEST_MEASUREMENTS_KEY = "latest_measurements"
ALERT_TIMEOUT_IN_SECONDS = 600

def production?
  ARGV[0] != "--test"
end

def main
  initialize_led

  loop do
    test_and_blink
  end
end

def initialize_led
  if production?
    `echo gpio > #{LED_TRIGGER_PATH}`
  end
end

def test_and_blink
  if latest_measurements.any? { |measurement| recent?(measurement) }
    blink(:slow)
  else
    blink(:fast)
  end
rescue StandardError => e
  blink(:fast)
end

def latest_measurements
  # A new Redis instance each time to better handle dropped connections
  with_redis do |redis|
    latest_measurements_str = redis.lrange LATEST_MEASUREMENTS_KEY, 0, 0

    latest_measurements_str.map {|measurement| JSON.parse(measurement) }
  end
end

def blink(speed)
  if speed == :slow
    delay = 1
  else
    delay = 0.2
  end

  on
  sleep delay
  off
  sleep delay
end

def recent?(measurement)
  time_stamp = DateTime.parse(measurement["time_stamp_utc"])

  second = 1.0 / 24 / 60 / 60

  old_at = DateTime.now - (ALERT_TIMEOUT_IN_SECONDS * second)

  return old_at < time_stamp
end

def with_redis
  redis = Redis.new

  yield redis
ensure
  redis.close
end

def on
  if production?
    `echo 0 > #{LED_BRIGHTNESS_PATH}`
  else
    puts "on"
  end
end

def off
  if production?
    `echo 1 > #{LED_BRIGHTNESS_PATH}`
  else
    puts "off"
  end
end

main
