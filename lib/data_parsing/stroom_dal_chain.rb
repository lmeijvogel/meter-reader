require_relative 'chainable'
require_relative 'kwh_reader'

class StroomDalChain < Chainable
  def can_handle?(line)
    line.start_with? ("1-0:1.8.1")
  end

  def handle(lines_enumerator, output)
    line = lines_enumerator.next

    output.stroom_dal = KwhReader.read(line)
  end
end
