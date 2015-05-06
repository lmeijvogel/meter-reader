require 'date'

require "p1_meter_reader/data_parsing/parse_chain/gas_chain"
require "p1_meter_reader/data_parsing/parse_chain/stroom_dal_chain"
require "p1_meter_reader/data_parsing/parse_chain/stroom_current_chain"
require "p1_meter_reader/data_parsing/parse_chain/stroom_piek_chain"
require "p1_meter_reader/data_parsing/parse_chain/skip_line_chain"

require "p1_meter_reader/models/measurement"

class MeasurementParser
  def initialize
    super

    @chain = StroomDalChain.new(
      StroomPiekChain.new(
        StroomCurrentChain.new(
          GasChain.new(
            SkipLineChain.new))))
  end

  def parse(input)
    output = Measurement.new

    input = input.lines.to_enum

    output.time_stamp = DateTime.now

    # Convert to UTC before storing
    output.time_stamp_utc = DateTime.now.new_offset(0)

    while (true)
      @chain.try(input, output)
    end
  rescue StopIteration
    return output
  end
end
