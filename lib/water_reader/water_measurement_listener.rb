require 'serialport'

module WaterReader
  class WaterMeasurementListener
    def initialize(input: serial_port)
      @input = input
      @stream = input.each_line
    end

    def read
      line = @stream.next

      line.strip
    end

    def ready?
      @input.ready?
    end

    private

    def serial_port
      serial_port = SerialPort.new("/dev/ttyACM0", 9600)
      serial_port.data_bits = 7
      serial_port.stop_bits = 1
      serial_port.parity = SerialPort::EVEN

      serial_port
    end
  end
end
