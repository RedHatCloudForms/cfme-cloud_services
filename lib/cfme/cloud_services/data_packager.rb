require "json"
require "tempfile"

class Cfme::CloudServices::DataPackager
  def self.package(payload, tempdir = nil)
    file = Tempfile.new(["cfme_inventory-", ".tar.gz"], tempdir)
    file.binmode

    targz(payload.map(&:to_json), file)

    file.close(false)

    path = Pathname.new(file.path)
    return path unless block_given?

    begin
      yield(path)
    ensure
      path.unlink
    end
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
