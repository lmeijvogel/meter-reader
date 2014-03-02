require_relative 'chainable'

class GasChain < Chainable
  def can_handle?(line)
    line.start_with? '0-1:24.3.0'
  end

  def handle(lines_enumerator, output)
    lines_enumerator.next # Skip the intro line
    line = lines_enumerator.next

    output.gas = line.match(/\((\d*\.\d*)\)/)[1].to_f
  end
end
