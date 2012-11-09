module MCProvision::Util
  # Parses a -S style filter and return a std filter option
  def self.parse_filter(agent, filter)
    result = MCollective::Util.empty_filter
    result["compound"] <<  MCollective::Matcher.create_compound_callstack(filter) unless filter.nil? || filter == ""
    result["agent"] << agent

    result
  end

  # Daemonize the current process
  def self.daemonize
    fork do
      Process.setsid
      exit if fork
      Dir.chdir('/tmp')
      STDIN.reopen('/dev/null')
      STDOUT.reopen('/dev/null', 'a')
      STDERR.reopen('/dev/null', 'a')

      if File.directory?("/var/run")
        File.open("/var/run/mcprovision.pid", 'w') {|f| f.write(Process.pid) } rescue true
      end

      yield
    end
  end

  def self.log(msg)
    MCProvision.debug(msg)
  end
end
