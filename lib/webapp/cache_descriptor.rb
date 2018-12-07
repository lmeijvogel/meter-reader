class CacheDescriptor
  def initialize(date, cache_dir)
    @cache_dir = cache_dir
    @date = date.to_time
  end

  def should_delete_cache?
    return false unless File.exist?(filename)

    return false if viewing_current_period?

    cache_in_period?
  end

  def filename
    raise NotImplementedError
  end

  def data_fixed?
    !viewing_current_period?
  end

  def temporary_cache_fresh?
    raise NotImplementedError
  end

  def cache_in_period?
    raise NotImplementedError
  end

  def viewing_current_period?
    raise NotImplementedError
  end
end
