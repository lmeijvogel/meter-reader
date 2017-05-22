class MonthCacheDescriptor
  def initialize(date, cache_dir)
    @cache_dir = cache_dir
    @date = date
  end

  def filename
    File.join(@cache_dir, @date.strftime("%Y-%m"))
  end

  def data_fixed?
    now = Time.now
    beginning_of_month = Time.new(now.year, now.month, 1)

    @date < beginning_of_month
  end

  def temporary_cache_fresh?
    yesterday = Time.now - 86400

    File.mtime(filename) > yesterday
  end
end
