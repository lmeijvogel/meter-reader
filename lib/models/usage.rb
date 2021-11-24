require 'ostruct'

module P1MeterReader
  module Models
    class Usage < OpenStruct
      def to_json(j)
        {
          time_stamp: time_stamp,
          label: label,
          stroom: stroom,
          gas: gas,
          water: water
        }.to_json(j)
      end
    end
  end
end
