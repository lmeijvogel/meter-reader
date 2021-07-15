module P1MeterReader
  module Models
    class Measurement
      attr_accessor :time_stamp, :time_stamp_utc, :stroom_dal, :stroom_piek, :gas, :water

      # At the moment, this initializer is only used for tests
      def initialize(time_stamp, time_stamp_utc, stroom_dal, stroom_piek, gas, water)
        self.time_stamp = time_stamp
        self.time_stamp_utc = time_stamp_utc
        self.stroom_dal = stroom_dal
        self.stroom_piek = stroom_piek
        self.gas = gas
        self.water = water
      end

      def time_stamp_current_minute
        self.time_stamp.strftime("%d-%m-%y %H:%M")
      end

      def time_stamp_next_minute
        next_minute = self.time_stamp + 1.0/(24*60)
        next_minute.strftime("%d-%m-%y %H:%M")
      end

      def to_s
        date = self.time_stamp.strftime("%d-%m-%y %H:%M:%S")

        "#{date}: #{stroom_dal} - #{stroom_piek} - #{gas}"
      end
    end
  end
end
