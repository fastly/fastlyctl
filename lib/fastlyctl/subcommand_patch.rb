class SubCommandBase < Thor
  def self.banner(command, namespace = nil, subcommand = false)
  	basename + " " + self::SubcommandPrefix + " " + command.usage
  end
end
