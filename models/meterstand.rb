require 'date'

require_relative "../lib/data_parsing/gas_chain.rb"
require_relative "../lib/data_parsing/stroom_dal_chain.rb"
require_relative "../lib/data_parsing/stroom_current_chain.rb"
require_relative "../lib/data_parsing/stroom_piek_chain.rb"
require_relative "../lib/data_parsing/skip_line_chain.rb"

require_relative "measurement.rb"

class Meterstand
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
