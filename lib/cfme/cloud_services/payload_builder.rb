module Cfme
  module CloudServices
    module PayloadBuilder
      INVENTORY_FILE_NAME = "cfme_inventory".freeze

      def gzipped_tar_file_from(payload)
        require 'rubygems/package'
        begin
          packed_file = Tempfile.new(INVENTORY_FILE_NAME)
          packed_file_path = packed_file.path

          File.open(packed_file_path, "wb") do |file|
            Zlib::GzipWriter.wrap(file) do |gz|
              Gem::Package::TarWriter.new(gz) do |tar|
                json_content = payload
                tar.add_file_simple(INVENTORY_FILE_NAME, 0o0444, json_content.length) do |io|
                  io.write(json_content)
                end
              end
            end
          end
          packed_file&.close
          yield(packed_file_path)
        ensure
          packed_file&.unlink
        end
      end
    end
  end
end
