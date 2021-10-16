require 'models/usage'

class DatabaseReader
  def initialize(connection_factory)
    @connection_factory = connection_factory
  end

  def read_for_day(date)
    start_date = sql_date(date)
    next_day = date.next_day

    # Include one measurement at the end of the day (the first one in the new day)
    end_date = sql_date(DateTime.civil(next_day.year, next_day.month, next_day.day, 1))

    query = "SELECT
      #{fields}
    FROM measurements
    WHERE time_stamp >= #{start_date} AND time_stamp <= #{end_date}
    GROUP BY YEAR(time_stamp), DAYOFYEAR(time_stamp), HOUR(time_stamp)"

    result = []
    @connection_factory.with_connection do |connection|
      result = connection.query(query).map do |row|
        to_usage(row)
      end

      if last_of_current_period?(date, "%Y-%m-%d")
        result.concat(last_recorded_entry(connection))
      end
    end

    result
  end

  def read_for_month(date)
    start_date = sql_date(date)
    end_date = sql_date(date.next_month + 1.0 / (24 * 4));

    query = "SELECT
      #{fields}
    FROM measurements
    WHERE time_stamp >= #{start_date} AND time_stamp <= #{end_date}
    GROUP BY YEAR(time_stamp), DAYOFYEAR(time_stamp)"

    @connection_factory.with_connection do |connection|
      result = connection.query(query).map do |row|
        to_usage(row)
      end

      next_timestamp = "DATE_ADD(CURDATE(), INTERVAL 1 DAY)"

      if last_of_current_period?(date, "%Y-%m")
        last_entry_query = "SELECT
          #{next_timestamp} as ts,
          TRUNCATE(stroom,3) as d_stroom,
          TRUNCATE(gas,3) as d_gas,
          TRUNCATE(water,3) as d_water
        FROM measurements
        ORDER BY id DESC
        LIMIT 1"

        last_entry_result = connection.query(last_entry_query).map do |row|
          to_usage(row)
        end

        result.concat(last_entry_result)
      end

      result
    end
  end

  def read_for_year(date)
    start_date = sql_date(date)
    end_date = sql_date(date.next_year + 1.0 / (24 * 4));

    query = "SELECT
      #{fields}
    FROM measurements
    WHERE time_stamp >= #{start_date} AND time_stamp <= #{end_date}
    GROUP BY YEAR(time_stamp), MONTH(time_stamp)"

    @connection_factory.with_connection do |connection|
      result = connection.query(query).map do |row|
        to_usage(row)
      end

      if last_of_current_period?(date, "%Y")
        next_timestamp = "DATE_ADD(CURDATE(), INTERVAL 1 MONTH)"

        last_entry_query = "SELECT
          #{next_timestamp} as ts,
          TRUNCATE(stroom,3) as d_stroom,
          TRUNCATE(gas,3) as d_gas,
          TRUNCATE(water,3) as d_water
        FROM measurements
        ORDER BY id DESC
        LIMIT 1"

        last_entry_result = connection.query(last_entry_query).map do |row|
          to_usage(row)
        end

        result.concat(last_entry_result)
      end

      result
    end
  end

  def last_recorded_entry(connection)
    next_timestamp = <<~HOUR
    DATE_SUB(
      DATE_SUB(
        DATE_ADD(NOW(), INTERVAL 1 HOUR)
        , INTERVAL MINUTE(
        NOW()
        ) MINUTE
      )
      , INTERVAL SECOND(NOW()) SECOND
    )
    HOUR

    last_entry_query = "SELECT
      #{next_timestamp} as ts,
      TRUNCATE(stroom,3) as d_stroom,
      TRUNCATE(gas,3) as d_gas,
      TRUNCATE(water,3) as d_water
    FROM measurements
    ORDER BY id DESC
    LIMIT 1"

    connection.query(last_entry_query).map do |row|
      to_usage(row)
    end
  end

  def last_of_current_period?(date, comparison_format)
    return date.strftime(comparison_format) == DateTime.now.strftime(comparison_format)
  end

  def last_measurement
    query = <<~QUERY
      SELECT
        time_stamp AS ts,
        stroom AS d_stroom,
        gas AS d_gas,
        water AS d_water
      FROM measurements
      WHERE id = (SELECT MAX(id) FROM measurements)
    QUERY

    @connection_factory.with_connection do |connection|
      row = connection.query(query).first

      return to_usage(row)
    end
  end

  private

  def sql_date(date)
    %Q|str_to_date('#{date.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}', "%Y-%m-%d %H:%i:%S")|
  end

  def to_usage(row)
    usage = P1MeterReader::Models::Usage.new
    usage.stroom_totaal = row["d_stroom"]
    usage.gas = row["d_gas"]
    usage.water = row["d_water"]
    usage.time_stamp = row["ts"].to_datetime

    usage
  end

  def fields
    <<~FIELDS
      MIN(time_stamp) as ts,
      TRUNCATE(MIN(stroom),3) as d_stroom,
      TRUNCATE(MIN(gas),3) as d_gas,
      TRUNCATE(MIN(water), 3) as d_water
    FIELDS
  end
end
