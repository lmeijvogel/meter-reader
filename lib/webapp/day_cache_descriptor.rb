require "webapp/cache_descriptor"

class DayCacheDescriptor < CacheDescriptor
  def filename
    File.join(@cache_dir, @date.strftime("%Y-%m-%d"))
  end

  def temporary_cache_fresh?
    false
  end

  def viewing_current_period?
    now = Time.now

    now.year == @date.year &&
      now.month == @date.month &&
      now.day == @date.day
  end

  def cache_in_period?
    file_created_at = File.mtime(filename)

    file_created_at.year == @date.year &&
      file_created_at.month == @date.month &&
      file_created_at.day == @date.day
  end
end
