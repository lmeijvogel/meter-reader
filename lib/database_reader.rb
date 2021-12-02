require 'models/usage'

class DatabaseReader
  def initialize(connection_factory)
    @connection_factory = connection_factory
  end

  def read_for_day(date)
    start_date = sql_date(date)

    next_day = date.next_day
    end_date = sql_date(DateTime.civil(next_day.year, next_day.month, next_day.day, 0))

    query = "SELECT
      MIN(HOUR(time_stamp)) as label,
      #{fields}
    FROM measurements
    WHERE time_stamp >= #{start_date} AND time_stamp < #{end_date}
    GROUP BY HOUR(time_stamp)"

    result = []
    @connection_factory.with_connection do |connection|
      result = connection.query(query).map do |row|
        to_usage(row)
      end

      last_entry_query = "SELECT
        (MAX(HOUR(time_stamp)) + 1) as label,
        #{fields_max}
      FROM measurements
      WHERE time_stamp >= #{start_date} AND time_stamp < #{end_date}"

      last_entry_result = connection.query(last_entry_query).map do |row|
        to_usage(row)
      end

      result.concat(last_entry_result)
    end

    result
  end

  def read_for_month(date)
    start_date = sql_date(date)
    end_date = sql_date(date.next_month + 1.0 / (24 * 4));

    query = "SELECT
        MIN(DAYOFMONTH(time_stamp)) as label,
        #{fields}
      FROM measurements
      WHERE time_stamp >= #{start_date} AND time_stamp < #{end_date}
      GROUP BY DAYOFMONTH(time_stamp)"

    @connection_factory.with_connection do |connection|
      result = connection.query(query).map do |row|
        to_usage(row)
      end

      last_entry_query = "SELECT
          (MAX(DAYOFMONTH(time_stamp)) + 1) as label,
          #{fields_max}
        FROM measurements
        WHERE time_stamp >= #{start_date} AND time_stamp < #{end_date}"

      last_entry_result = connection.query(last_entry_query).map do |row|
        to_usage(row)
      end

      result.concat(last_entry_result)

      result
    end
  end

  def read_for_year(date)
    start_date = sql_date(date)
    end_date = sql_date(date.next_year + 1.0 / (24 * 4));

    now = DateTime.now

    # Due to moving house in 2021, the meter readouts are no longer strictly
    # increasing, so just picking max(value) for the whole year will give errors:
    # The absolute readouts in the previous house were higher.
    #
    # To circumvent this, if it's the current year, start from the current month since
    # we're not strictly sure that e.g. december is filled in.
    # If it's from a previous year, we do know that december is filled in, so we pick that.
    start_of_last_month = if date.year == DateTime.now.year
                            sql_date(DateTime.new(now.year, now.month, 1))
                          else
                            sql_date(DateTime.new(date.year, 12, 1))
                          end

    query = "SELECT
        MIN(MONTH(time_stamp)) as label,
        #{fields}
      FROM measurements
      WHERE time_stamp >= #{start_date} AND time_stamp < #{end_date}
      GROUP BY MONTH(time_stamp)"

    @connection_factory.with_connection do |connection|
      result = connection.query(query).map do |row|
        to_usage(row)
      end

      last_entry_query = "SELECT
          (MAX(MONTH(time_stamp)) + 1) as label,
          #{fields_max}
        FROM measurements
        WHERE time_stamp >= #{start_of_last_month} AND time_stamp < #{end_date}"

      last_entry_result = connection.query(last_entry_query).map do |row|
        to_usage(row)
      end

      result.concat(last_entry_result)

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
    usage.stroom = row["d_stroom"]
    usage.gas = row["d_gas"]
    usage.water = row["d_water"]
    usage.time_stamp = row["ts"].to_datetime
    usage.label = row["label"]

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

  def fields_max
    <<~FIELDS
      MAX(time_stamp) as ts,
      TRUNCATE(MAX(stroom),3) as d_stroom,
      TRUNCATE(MAX(gas),3) as d_gas,
      TRUNCATE(MAX(water), 3) as d_water
    FIELDS
  end
end
