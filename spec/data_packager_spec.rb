RSpec.describe Cfme::CloudServices::DataPackager do
  describe "#package" do
    let(:payload) { [{"data" => "XXX"}] }

    def unpack_tar_gz(io)
      require "rubygems/package"

      Zlib::GzipReader.wrap(io) do |gz|
        Gem::Package::TarReader.new(gz) do |tar|
          tar.each { |entry| yield entry }
        end
      end
    end

    it "creates a valid .tar.gz file" do
      file_path = described_class.package(payload)
      unpack_tar_gz(File.open(file_path)) do |file_stream|
        require "json/stream"
        inventory = JSON::Stream::Parser.parse(file_stream)
        expect(inventory).to eq(payload.first)
      end
    end
  end
end
