module P1MeterReader
  module Models
    class Measurement
      attr_accessor :time_stamp,
        :time_stamp_utc,
        :stroom_dal,
        :stroom_piek,
        :levering_dal,
        :levering_piek,
        :stroom_current,
        :gas,
        :water

      def initialize(time_stamp = nil, time_stamp_utc = nil, stroom_dal = nil, stroom_piek = nil, levering_dal = nil, levering_piek = nil, stroom_current = nil, gas = nil, water = nil)
        @time_stamp = time_stamp
        @time_stamp_utc = time_stamp_utc
        @stroom_dal = stroom_dal
        @stroom_piek = stroom_piek
        @levering_dal = levering_dal
        @levering_piek = levering_piek
        @stroom_current = stroom_current
        @gas = gas
        @water = water
      end

      def stroom
        @stroom_dal + @stroom_piek
      end

      def levering
        @levering_dal + @levering_piek
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

        "#{date}: verbruik_dal: #{stroom_dal} - verbruik_piek: #{stroom_piek} - levering_dal: #{levering_dal} - levering_piek: #{levering_piek} - gas: #{gas} - water: #{water} - current: #{stroom_current}"
      end
    end
  end
end
