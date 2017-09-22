Rails.application.config.middleware.use OmniAuth::Builder do
  Setting.omniauth.providers.each do |provider, data|
    data = data.deep_symbolize_keys
    redirect_uri = "#{Setting.default_protocol}://#{Setting.host}/authorizations/#{provider}/callback"
    provider provider, data[:token], data[:secret], (data[:options] || {}).merge(redirect_uri: redirect_uri)
  end
end

OmniAuth.config.path_prefix = "/authorizations"
