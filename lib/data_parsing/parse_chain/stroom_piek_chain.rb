require 'data_parsing/parse_chain/chainable'
require 'data_parsing/kwh_reader'

class StroomPiekChain < Chainable
  attr_accessor :last_value

  def initialize(next_chain = nil)
    super
    self.last_value = 0.0.kWh
  end

  def can_handle?(line)
    line.start_with?("1-0:1.8.2")
  end

  def handle(lines_enumerator, output)
    line = lines_enumerator.next

    value = KwhReader.read(line)
    output.stroom_piek = value
    output.diff_stroom_piek = value - last_value

    self.last_value = value
  end
end
