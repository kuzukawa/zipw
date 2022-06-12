require "zipw"
require "thor"

module ZipW
  class CLI < Thor
    class << self
      def exit_on_failure?
        true
      end
    end

    desc "zipw [file_or_directory ...]", "zip target files or directories that works on windows without garbled"
    def zipw (str)
      begin
        zip = Zipw::WindowsZip.new(ARGV[1..])
      rescue => e
        puts e.message
        exit 1
      end

      zip.create
    end
  end
end
