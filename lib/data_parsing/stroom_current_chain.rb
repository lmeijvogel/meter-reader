require_relative 'chainable'
require_relative 'kwh_reader'

class StroomCurrentChain < Chainable
  def can_handle?(line)
    line.start_with? ("1-0:1.7.0")
  end

  def handle(lines_enumerator, output)
    line = lines_enumerator.next

    match = line.match(/\((.*)\*kW\)/)
    output.stroom_current = match[1].to_f if match
  end
end
