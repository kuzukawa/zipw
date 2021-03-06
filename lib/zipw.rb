# frozen_string_literal: false

require_relative "zipw/version"
require_relative "zipw/cli"

require "zip"

module Zipw
  class Error < StandardError; end

  class WindowsZip
    def initialize(param)
      @targets = param
      @targets_basename = {}
      @zip_file = File.dirname(param[0]) + '/Archive.zip'

      @targets.each do |f|
        unless File.exist? f
          raise "file or directory not found #{f}"
        end
        @targets_basename[f] = File.basename(f)
      end

      if File.exist?(@zip_file)
        raise "#{@zip_file} already exists."
      end
    end

    def create
      Zip::File.open(@zip_file, Zip::File::CREATE) do |zf|
        @targets.each do |t|
          if File.directory?(t)
            zip_directory(t, zf)
          elsif
          write_entry(File.basename(t) ,t, zf)
          end
        end
      end
    end

    private

    def zip_directory(target, zip_file)
      entries = Dir.entries(target) - %w[. .. .DS_Store]
      write_entries entries, target, @targets_basename[target], zip_file
    end

    def write_entries(entries, path, basename, zip_file)
      entries.each do |e|
        zip_file_path = "#{basename}/#{e}"
        file_path = path == '' ? e : File.join(path, e)

        if File.directory? file_path
          zip_file.mkdir zip_file_path
          sub_dir = Dir.entries(file_path) - %w[. .. .DS_Store]
          write_entries(sub_dir, file_path, zip_file_path, zip_file)
        else
          write_entry(zip_file_path, file_path, zip_file)
        end
      end
    end

    def write_entry(zip_file_path, file_path, zip_file)
      zip_file.add(windows_filename(zip_file_path), file_path)
    end

    def windows_filename(utf8, is_file = true)
      if (is_file and /[\\\/:*"<>|]/ === File.basename(utf8)) or
        (!is_file and /[\\:*"<>|]/ === utf8)
        raise "Can't use on windows #{utf8}"
      end

      undefined_signs = {
        "\u2014" => "\x81\x5C".force_encoding(Encoding::WINDOWS_31J), # — EM DASH
        "\u301C" => "\x81\x60".force_encoding(Encoding::WINDOWS_31J), # 〜 WAVE DASH
        "\u2016" => "\x81\x61".force_encoding(Encoding::WINDOWS_31J), # ‖ DOUBLE VERTICAL LINE
        "\u2212" => "\x81\x7C".force_encoding(Encoding::WINDOWS_31J), # − MINUS SIGN
        "\u00A2" => "\x81\x91".force_encoding(Encoding::WINDOWS_31J), # ¢ CENT SIGN
        "\u00A3" => "\x81\x92".force_encoding(Encoding::WINDOWS_31J), # £ POUND SIGN
        "\u00AC" => "\x81\xCA".force_encoding(Encoding::WINDOWS_31J), # ¬ NOT SIGN
      }
      utf8.unicode_normalize(:nfc).encode(Encoding::WINDOWS_31J, fallback: undefined_signs)
    end
  end
end
