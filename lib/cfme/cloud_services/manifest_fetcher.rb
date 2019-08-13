class Cfme::CloudServices::ManifestFetcher
  def self.fetch(force: false)
    raw_manifest_clear_cache if force

    manifest = Vmdb::Settings.filter_passwords!(JSON.parse(raw_manifest))
    block_given? ? yield(manifest) : manifest
  end

  private_class_method def self.manifest_configuration
    ::Settings.cfme_cloud_services.manifest_configuration
  end

  private_class_method def self.certificate_options
    {:ssl_client_cert => OpenSSL::X509::Certificate.new(File.read("/etc/pki/consumer/cert.pem")),
     :ssl_client_key  => OpenSSL::PKey::RSA.new(File.read("/etc/pki/consumer/key.pem"))}
  end

  private_class_method def self.ssl_options
    {:verify_ssl => manifest_configuration.verify_ssl ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE}
  end

  cache_with_timeout(:raw_manifest) do
    begin
      uri = URI::Generic.build(
        :scheme => manifest_configuration.scheme,
        :host   => manifest_configuration.host,
        :port   => manifest_configuration.port,
        :path   => File.join(manifest_configuration.path, Vmdb::Appliance.VERSION)
      )

      options = certificate_options.merge(ssl_options)

      response = RestClient::Resource.new(uri.to_s, options)
      response.get
    rescue StandardError => e
      _log.error("Error with obtaining manifest with schema: #{e.message}")
      raise
    end
  end
  private_class_method :raw_manifest
end
