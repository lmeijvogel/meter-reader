require 'date'

require 'influxdb-client'

class InfluxDBClient
  def initialize(hostname:, org:, bucket:, token:)
    @hostname = hostname
    @org = org
    @bucket = bucket
    @token = token
  end

  def client
    @client ||= InfluxDB2::Client.new("http://#{@hostname}:8086", @token,
                                      org: @org,
                                      bucket: @bucket,
                                      use_ssl: false,
                                      precision: InfluxDB2::WritePrecision::NANOSECOND)
  end

  def send_water_tick
    write_api.write(data: {
      name: 'water',
      fields: { water: 1 }, time: Time.now
    })
  end

  def send_stroom_reading(reading)
    write_api.write(data: {
      name: 'stroom',
      fields: { stroom: reading.to_f }, time: Time.now
    })
  end

  def send_levering_reading(reading)
    write_api.write(data: {
      name: 'levering',
      fields: { levering: reading.to_f }, time: Time.now
    })
  end

  def send_current_reading(current, generation)
    write_api.write(data: {
      name: 'current',
      fields: { current: current.to_f, generation: generation.to_f }, time: Time.now
    })
  end

  def send_gas_reading(reading)
    write_api.write(data: {
      name: 'gas',
      fields: { gas: reading.to_f }, time: Time.now
    })
  end

  def send_opwekking_reading(reading, time)
    write_api.write(data: {
      name: 'opwekking',
      fields: { opwekking: reading.to_i }, time: time
    })
  end

  def write_api
    @write_api ||= client.create_write_api
  end
end
