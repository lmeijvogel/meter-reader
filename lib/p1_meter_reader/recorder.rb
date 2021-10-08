require "p1_meter_reader/data_parsing/measurement_parser"

module P1MeterReader
  class Recorder
    def initialize(p1_data_source:)
      self.measurement_parser = Models::MeasurementParser.new
      self.p1_data_source = p1_data_source
    end

    def collect_data(&block)
      loop do
        collect_measurement(&block)
      end
    end

    def collect_measurement(&block)
      p1_message = p1_data_source.read

      measurement = measurement_parser.parse(p1_message)

      block.yield measurement
    end

    protected

    attr_accessor :measurement_parser, :p1_data_source
  end
end
