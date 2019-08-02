RSpec.describe Cfme::CloudServices::ManifestFetcher do
  describe "#fetch" do
    let(:cfme_version) { Vmdb::Appliance.VERSION }

    let(:expected_json_manifest) do
      {"cfme_version" => cfme_version,
       "manifest"     => {"ManageIQ::Providers::OpenStack::CloudManager" => {
           "id"   => nil,
           "name" => nil
       }}}
    end

    let(:manifest_response) do
      <<~EOJ
        {
          "cfme_version":"#{cfme_version}",
          "manifest":
          {
            "ManageIQ::Providers::OpenStack::CloudManager":{"id":null,"name":null}
          }
        }
      EOJ
    end

    let(:key) do
      OpenSSL::PKey::RSA.new(2048)
    end

    let(:cert) do
      name = OpenSSL::X509::Name.parse("CN=example.com/C=EE")
      cert = OpenSSL::X509::Certificate.new
      cert.version     = 2
      cert.serial      = 0
      cert.not_before  = Time.now
      cert.not_after   = cert.not_before + 1 * 365 * 24 * 60 * 60 # 1 year validity
      cert.public_key  = key.public_key
      cert.subject     = name
      cert.issuer      = name
      cert.sign key, OpenSSL::Digest::SHA1.new
      cert
    end

    let(:certificate) do
      {:ssl_client_cert => cert.to_pem,
       :ssl_client_key  => key,
       :verify_ssl      => OpenSSL::SSL::VERIFY_PEER}
    end

    it "fetches manifest" do
      uri_config = ::Settings.cfme_cloud_services.manifest_configuration
      uri = URI::Generic.build(
        :scheme => uri_config.scheme,
        :host   => uri_config.host,
        :port   => uri_config.port,
        :path   => File.join(uri_config.path, Vmdb::Appliance.VERSION)
      )

      allow(described_class).to receive(:certificate_config).and_return(certificate)

      require 'rest-client'

      expect(RestClient::Resource).to receive(:new).with(uri.to_s, certificate).and_return(RestClient::Resource.new(nil))
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_return(manifest_response)

      expect(described_class.send(:fetch)).to eq(expected_json_manifest)
    end

    let(:fake_configuration) do
      {
        :scheme => "https",
        :host   => "fakeXXXX.XXXX",
        :path   => "/api"
      }
    end

    it 'raises error when there is issue on endpoint' do
      require 'rest-client'
      allow(::Settings.cfme_cloud_services).to receive(:manifest_configuration).and_return(OpenStruct.new(fake_configuration))
      allow(described_class).to receive(:certificate_options).and_return(certificate)

      expect { described_class.send(:raw_manifest) }.to raise_error StandardError
    end
  end
end
