require "json"
require "net/http"
require "errors"

module Client

  class Client

    def initialize(url)
      user_and_pass = url.match(/(\w+):(\w+)/)
      @user, @password = user_and_pass[1], user_and_pass[2]
      @url = url.match(/@(.*):/)[1]
      @port = url.match(/([0-9]+)(\/)?$/)[1]
    end

    def granulate_doc(file, filename, options = {})
      @request_data = Hash.new
      if options[:doc_link]
        insert_download_data options
      else
        @request_data.merge! {:file => file, :filename => filename}
      end
      insert_callback_data options
      request = prepare_request :POST, @request_data
      execute_request(request)
    end

    private

    def insert_download_data(options)
      @request_data.merge! {:doc_link => options[:doc_link]}
    end

    def insert_callback_data(options)
        @request_data[:callback] = options[:callback] unless options[:callback].nil?
        @request_data[:verb] = options[:verb] unless options[:verb].nil?
    end

    def prepare_request(verb, body)
      verb = verb.to_s.capitalize!
      request = Net::HTTP.const_get("#{verb}").new '/'
      request.body = body
      request.basic_auth @user, @password
      request
    end

    def execute_request(request)
      response = Net::HTTP.start @url, @port do |http|
        http.request(request)
      end
      raise NSICloudooo::Errors::Client::KeyNotFoundError if response.code == "404"
      JSON.parse(response.body)
    end
  end
end
