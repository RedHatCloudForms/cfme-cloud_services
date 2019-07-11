require "json"
require "tempfile"

class Cfme::CloudServices::DataPackager
  def self.package(payload)
    file = Tempfile.new(["cfme_inventory", ".tar.gz"])
    file.binmode

    targz(payload.map(&:to_json), file)

    file.close(false)

    path = Pathname.new(file.path)
    block_given? ? yield(path) : path
  end

  private_class_method def self.targz(files, io = StringIO.new)
    require 'rubygems/package'
    Zlib::GzipWriter.wrap(io) do |gz|
      Gem::Package::TarWriter.new(gz) do |tar|
        files.each_with_index do |file, i|
          tar.add_file_simple("cfme_inventory_#{i}.json", 0o0444, file.length) do |tar_file|
            tar_file.write(file)
          end
        end
      end
    end
  end
end
