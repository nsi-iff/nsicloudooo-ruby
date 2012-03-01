require "json"
require "net/http"
require File.dirname(__FILE__) + '/errors'

module NSICloudooo
  class Client

    def initialize(url)
      user_and_pass = url.match(/(\w+):(\w+)/)
      @user, @password = user_and_pass[1], user_and_pass[2]
      @url = url.match(/@(.*):/)[1]
      @port = url.match(/([0-9]+)(\/)?$/)[1]
    end

    def granulate(options = {})
      @request_data = Hash.new
      if options[:doc_link]
        insert_download_data options
      else
        file_data = {:doc => options[:file], :filename => options[:filename]}
        @request_data.merge! file_data
      end
      insert_callback_data options
      request = prepare_request :POST, @request_data.to_json
      execute_request(request)
    end

    def done(key)
      request = prepare_request :GET, {:key => key}.to_json
      execute_request(request)
    end

    private

    def insert_download_data(options)
      download_data = {doc_link: options[:doc_link]}
      @request_data.merge! download_data
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
