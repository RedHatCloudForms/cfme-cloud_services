class Cfme::CloudServices::DataUploader
  include Vmdb::Logging

  def self.upload(path)
    _log.info("Uploading #{path} to cloud.redhat.com...")

    params = {:payload= => path, :content_type= => "application/vnd.redhat.topological-inventory.something+tgz"}
    result = AwesomeSpawn.run("insights-client", :params => params)
    if result.failure?
      _log.error("Uploading #{path} to cloud.redhat.com...Failure - #{result.output} #{result.error}")
    else
      _log.info("Uploading #{path} to cloud.redhat.com...Success - #{result.output}")
    end
    result.success?
  rescue StandardError => e
    _log.error "Error uploading to cloud.redhat.com: #{e}"
    false
  end
end
