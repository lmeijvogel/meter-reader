module P1MeterReader
  module DataParsing
    class FakeStreamSplitter
      def initialize
        @stroom_dal = 2018.0
        @stroom_piek = 2293.0
        @current = 0
        @gas = 2246.0
      end

      def record
        <<~RECORD
          /XMX5XMXABCE100129872

          0-0:96.1.1(4B414145303031343535343236383133)
          1-0:1.8.1(#{pretty_print @stroom_dal }*kWh)
          1-0:1.8.2(#{pretty_print @stroom_piek }*kWh)
          1-0:2.8.1(00000.000*kWh)
          1-0:2.8.2(00000.000*kWh)
          0-0:96.14.0(0002)
          1-0:1.7.0(#{pretty_print @current }*kW)
          1-0:2.7.0(0000.00*kW)
          0-0:17.0.0(999*A)
          0-0:96.3.10(1)
          0-0:96.13.1()
          0-0:96.13.0()
          0-1:96.1.0(3238303131303038333338303831393133)
          0-1:24.1.0(03)
          0-1:24.2.1(150327210000)(00)(60)(1)(#{pretty_print @gas}*m3)
          (02246.014)
          0-1:24.4.0(1)
          !
        RECORD
      end

      def ready?
        true
      end

      def read
        sleep 1

        if Random.rand < 0.05
          @stroom_piek += (2 * Random.rand)
        end
        if Random.rand < 0.05
          @stroom_dal += (2 * Random.rand)
        end
        if Random.rand < 0.05
          @gas += (2 * Random.rand)
        end

        @current = Random.rand * 3;

        return record
      end

      def pretty_print(value)
        format("%09.3f", value)
      end
    end
  end
end
