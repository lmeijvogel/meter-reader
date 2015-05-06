require 'p1_meter_reader/float_extensions'

module KwhReader
  def read(line)
    match = line.match(/\((.*)\*kWh\)/)

    match[1].to_f.kWh if match
  end

  module_function :read
end
