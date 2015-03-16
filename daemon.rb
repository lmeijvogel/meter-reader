class Daemon
  def initialize(process_name:, pidfile:, daemonize: true)
    self.pidfile = pidfile
    self.process_name = process_name
    self.daemonize = daemonize
  end

  def run
    ensure_no_current_instance!
    ensure_pidfile_writable!

    at_exit { File.unlink(pidfile) if File.exist?(pidfile) }

    $0 = process_name
    Process.daemon if self.daemonize

    write_pidfile()
    yield
  end

  protected
  def ensure_no_current_instance!
    return if !File.exists?(pidfile)

    stored_pid = Integer(File.read(pidfile))

    begin
      Process.getpgid(stored_pid)

      raise "A process is already running: #{stored_pid}!"
    rescue Errno::ESRCH
      return
    end
  end

  def ensure_pidfile_writable!
    directory_writeable = File.writable?(File.dirname(pidfile))
    pidfile_writable = File.writable?(pidfile)

    unless ( directory_writeable || pidfile_writable )
      raise "Cannot write PID file at #{pidfile}"
    end
  end

  def write_pidfile
    File.open(pidfile, "w") do |file|
      file.puts Process.pid.to_s
    end
  end

  attr_accessor :process_name, :pidfile, :daemonize
end
