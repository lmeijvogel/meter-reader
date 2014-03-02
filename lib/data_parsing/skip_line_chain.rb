require_relative 'chainable'

class SkipLineChain < Chainable
  def can_handle?(_)
    true
  end

  def handle(lines_enumerator, _)
    lines_enumerator.next
  end
end
