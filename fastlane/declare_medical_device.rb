# Health & Fitness listings must declare regulated-medical-device status
# before Apple will accept a review submission. Answer is No — see
# fastlane/metadata/regulated_medical_device.txt.

module GFDeclareMedicalDevice
  FILE = File.expand_path("metadata/regulated_medical_device.txt", __dir__)

  def submit!(options)
    declare_not_regulated_medical_device!
    super
  end

  def declare_not_regulated_medical_device!
    raw = File.exist?(FILE) ? File.read(FILE).strip.downcase : ""
    unless %w[false no 0].include?(raw)
      UI.user_error!("fastlane/metadata/regulated_medical_device.txt must be false")
    end

    app = Deliver.cache[:app]
    UI.message("Declaring Castellum is not a regulated medical device")

    errors = []
    [
      { isRegulatedMedicalDevice: false },
      { regulatedMedicalDevice: false },
    ].each do |attrs|
      begin
        app.update(attributes: attrs)
        UI.success("App Store Connect accepted #{attrs.keys.first}=false")
        return
      rescue StandardError => error
        errors << error.message
      end
    end

    http = tunes_http
    if http
      begin
        existing = http.get("apps/#{app.id}/regulatoryInfo")
        rid = existing&.body&.dig("data", "id")
        if rid
          http.patch(
            "apps/#{app.id}/regulatoryInfo",
            {
              data: {
                type: "appRegulatoryInfos",
                id: rid,
                attributes: { isRegulatedMedicalDevice: false },
              },
            }
          )
          UI.success("Patched apps/#{app.id}/regulatoryInfo isRegulatedMedicalDevice=false")
          return
        end
      rescue StandardError => error
        errors << error.message
      end

      begin
        http.post(
          "appRegulatoryInfos",
          {
            data: {
              type: "appRegulatoryInfos",
              attributes: { isRegulatedMedicalDevice: false },
              relationships: {
                app: { data: { type: "apps", id: app.id } },
              },
            },
          }
        )
        UI.success("Created appRegulatoryInfos isRegulatedMedicalDevice=false")
        return
      rescue StandardError => error
        errors << error.message
      end
    end

    UI.user_error!(
      "Could not declare regulated medical device = No. " \
      "#{errors.uniq.join(' | ')}"
    )
  end

  def tunes_http
    if Spaceship::ConnectAPI.respond_to?(:client) && Spaceship::ConnectAPI.client.respond_to?(:tunes_request_client)
      return Spaceship::ConnectAPI.client.tunes_request_client
    end
    if Spaceship::ConnectAPI.respond_to?(:tunes_request_client)
      return Spaceship::ConnectAPI.tunes_request_client
    end
    nil
  end
end

Deliver::SubmitForReview.prepend(GFDeclareMedicalDevice)
