# frozen_string_literal: true

module StirFry
  module CLI # :nodoc:
    autoload :New, "stir_fry/cli/new"
    autoload :Run, "stir_fry/cli/run"

    def self.call
      case ARGV.shift
      when "new" then New.call
      when "run" then Run.call
      else help
      end
    end

    def self.help
      puts <<~HEREDOC
        Usage: stirfry <subcommand> [options]

        🥡 Utility tool for the stirfry ruby library.

        Subcommands:
          new  generate a new StirFry project.
          run  run a stirfry app and reload on file changes.

      HEREDOC
      exit(0)
    end
  end
end
