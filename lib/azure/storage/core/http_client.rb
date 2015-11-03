#-------------------------------------------------------------------------
# # Copyright (c) Microsoft and contributors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#--------------------------------------------------------------------------

module Azure::Core
  module HttpClient
    # Returns the http agent based on uri
    # @param uri  [URI|String] the base uri (scheme, host, port) of the http endpoint
    # @return [Net::HTTP] http agent for a given uri
    def agents(uri)
      uri = URI.parse(uri) if uri.is_a?(String)
      key = uri.scheme.to_s + uri.host.to_s + uri.port.to_s
      @agents ||= {}
      unless @agents.key?(key)
        @agents[key] = build_http(uri)
      end
      @agents[key]
    end

    # Empties all the http agents
    def reset_agents!
      @agents = nil
    end

    private

    def build_http(uri)
      ssl_options = {}
      if uri.scheme.downcase == 'https'
        ssl_options[:ca_file] = self.ca_file if self.ca_file
        ssl_options[:verify] = true
      end
      proxy_options = if ENV['HTTP_PROXY']
                        URI::parse(ENV['HTTP_PROXY'])
                      elsif ENV['HTTPS_PROXY']
                        URI::parse(ENV['HTTPS_PROXY'])
                      end || nil
      Faraday.new(uri, ssl: ssl_options, proxy: proxy_options) do |conn|
        conn.use FaradayMiddleware::FollowRedirects
        conn.adapter Faraday.default_adapter
      end
    end
  end
end