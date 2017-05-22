class DayCacheDescriptor
  def initialize(date, cache_dir)
    @cache_dir = cache_dir
    @date = date
  end

  def filename
    File.join(@cache_dir, @date.strftime("%Y-%m-%d"))
  end

  def data_fixed?
    now = Time.now
    today = Time.new(now.year, now.month, now.day)

    @date < today
  end

  def temporary_cache_fresh?
    false
  end
end
