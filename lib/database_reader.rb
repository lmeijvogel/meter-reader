require 'ostruct'

require 'p1_meter_reader/models/usage'

class DatabaseReader
  def initialize(client)
    @client = client
  end

  def read
    query = "SELECT
      MIN(#{adjusted_time_stamp}) as ts,
      TRUNCATE(MIN(stroom_piek+stroom_dal),3) as d_totaal,
      TRUNCATE(MIN(gas),3) as d_gas
    FROM measurements
    #{where}
    GROUP BY #{granularity}
    #{optional_union_with_last}"

    @client.query(query).map do |row|
      usage = P1MeterReader::Models::Usage.new
      usage.stroom_totaal = row["d_totaal"]
      usage.gas = row["d_gas"]
      usage.time_stamp = row["ts"].to_datetime

      usage
    end
  end

  def day=(date)
    @start_date = date
    start_date = sql_date(date)
    next_day = date.next_day

    # Include one measurement at the end of the day (the first one in the new day)
    end_date = sql_date(DateTime.civil(next_day.year, next_day.month, next_day.day, 1))
    self.where = "WHERE #{adjusted_time_stamp} >= #{start_date} AND #{adjusted_time_stamp} <= #{end_date}"
    self.granularity = :hour
  end

  def month=(date)
    @start_date = date
    start_date = sql_date(date)
    end_date = sql_date(date.next_month + 1.0 / (24 * 4));
    self.where = "WHERE #{adjusted_time_stamp} >= #{start_date} AND #{adjusted_time_stamp} <= #{end_date}"
    self.granularity = :day
  end

  def year=(date)
    @start_date = date
    start_date = sql_date(date)
    end_date = sql_date(date.next_year + 1.0 / (24 * 4));
    self.where = "WHERE #{adjusted_time_stamp} >= #{start_date} AND #{adjusted_time_stamp} <= #{end_date}"
    self.granularity = :month
  end

  def granularity
    case @granularity
    when :hour
      "YEAR(#{adjusted_time_stamp}), DAYOFYEAR(#{adjusted_time_stamp}), HOUR(#{adjusted_time_stamp})"
    when :day
      "YEAR(#{adjusted_time_stamp}), DAYOFYEAR(#{adjusted_time_stamp})"
    when :month
      "YEAR(#{adjusted_time_stamp}), MONTH(#{adjusted_time_stamp})"
    else
      raise "Unknown granularity for data selection: #{@granularity}"
    end
  end

  def is_last_of_current_period?
    comparison_format = case @granularity
    when :hour
      "%Y-%m-%d"
    when :day
      "%Y-%m"
    when :month
      "%Y"
    else
      raise "Unknown granularity for data selection: #{@granularity}"
    end

    return @start_date.strftime(comparison_format) == DateTime.now.strftime(comparison_format)
  end

  protected
  attr_accessor :where
  attr_writer :granularity

  def optional_union_with_last
    if is_last_of_current_period?
      return <<-QUERY
        UNION SELECT
          #{next_timestamp} as ts,
          TRUNCATE(MAX(stroom_piek+stroom_dal),3) as d_totaal,
          TRUNCATE(MAX(gas),3) as d_gas
        FROM measurements
      QUERY
    end
  end

  private
  def adjusted_time_stamp
    "time_stamp"
  end

  def next_timestamp
    case @granularity
    when :hour
      "DATE_SUB(DATE_SUB(DATE_ADD(NOW(), INTERVAL 1 HOUR), INTERVAL MINUTE(NOW()) MINUTE), INTERVAL SECOND(NOW()) SECOND)"
    when :day
      "DATE_ADD(CURDATE(), INTERVAL 1 DAY)"
    when :month
      "DATE_ADD(CURDATE(), INTERVAL 1 MONTH)"
    else
      raise "Unknown granularity for data selection: #{@granularity}"
    end
  end

  def sql_date(date)
    %Q|str_to_date('#{date.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}', "%Y-%m-%d %H:%i:%S")|
  end
end
