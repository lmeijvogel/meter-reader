require_relative "../lib/data_parsing/gas_chain.rb"
require_relative "../lib/data_parsing/stroom_dal_chain.rb"
require_relative "../lib/data_parsing/stroom_piek_chain.rb"
require_relative "../lib/data_parsing/skip_line_chain.rb"

class Meterstand < OpenStruct
  def initialize
    super

    @chain = StroomDalChain.new(StroomPiekChain.new(GasChain.new(SkipLineChain.new)))
  end

  def parse(input)
    output = OpenStruct.new

    input = input.lines.to_enum

    output.time_stamp = DateTime.now

    while (true)
      @chain.try(input, output)
    end
  rescue StopIteration
    return output
  end
end
