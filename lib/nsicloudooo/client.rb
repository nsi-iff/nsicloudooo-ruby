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

    # Send a document be granulated by a nsi.cloudooo node
    #
    # @param [Hash] options used to send a document to be graulated
    # @option options [String] file the base64 encoded file to be granulated
    # @option options [String] sam_uid the UID of a document at SAM
    # @option options [String] filename the filename of the document
    # @note the filename is very importante, the cloudooo node will convert the document based on its filename, if necessary
    # @option options [String] doc_link link to the document that'll be granulated
    # @note if provided both doc_link and file options, file will be ignored and the client will download the document instead
    # @option options [String] callback a callback url to the file granulation
    # @option options [String] verb the callback request verb, when not provided, nsi.cloudooo default to POST
    #
    # @example A simple granulation
    #   doc = Base64.encode64(File.new('document.odt', 'r').read)
    #   nsicloudooo.granulate(:file => doc, :filename => 'document.odt')
    # @example Granulating from a SAM uid
    #   doc = Base64.encode64(File.new('document.odt', 'r').read)
    #   response = sam.store {:doc => doc, :granulated => false}
    #   doc_key = response["key"]
    #   nsicloudooo.granulate(:sam_uid => doc_key, :filename => 'document.odt')
    # @example Downloading and granulating from web
    #   nsicloudooo.granulate(:doc_link => 'http://google.com/document.odt')
    # @example Sending a callback url
    #   doc = Base64.encode64(File.new('document.odt', 'r').read)
    #   nsicloudooo.granulate(:file => doc, :filename => 'document.odt', :callback => 'http://google.com')
    #   nsicloudooo.granulate(:doc_link => 'http://google.com/document.odt', :callback => 'http://google.com')
    # @example Using a custom verb to the callback
    #   doc = Base64.encode64(File.new('document.odt', 'r').read)
    #   nsicloudooo.granulate(:file => doc, :filename => 'document.odt', :callback => 'http://google.com', :verb => "PUT")
    #   nsicloudooo.granulate(:doc_link => 'http://google.com/document.odt', :callback => 'http://google.com', :verb => "PUT")
    #
    # @return [Hash] response
    #   * "doc_key" [String] the key to access the granulated document if the sam node it was stored
    def granulate(options = {})
      @request_data = Hash.new
      if options[:doc_link]
        insert_download_data options
      elsif options[:sam_uid]
        file_data = {:sam_uid => options[:sam_uid], :filename => options[:filename]}
        @request_data.merge! file_data
      else
        file_data = {:doc => options[:file], :filename => options[:filename]}
        @request_data.merge! file_data
      end
      insert_callback_data options
      request = prepare_request :POST, @request_data.to_json
      execute_request(request)
    end

    # Verify if a document is already granulated
    #
    # @raise NSICloudooo::Errors::Client:KeyNotFoundError when an invalid document key is provided
    #
    # @param [String] key of the desired document
    # @return [Hash] response
    #   * "done" [String] true if the document was already granualted, otherwise, false
    #
    # @example
    #   nsicloudooo.done("some key")
    def done(key)
      request = prepare_request :GET, {:key => key}.to_json
      execute_request(request)
    end

    # Return the keys of the grains of a document
    #
    # @raise NSICloudooo::Errors::Client:KeyNotFoundError when an invalid document key is provided
    #
    # @param [String] key of the desired document
    # @return [Hash] response
    #   * "images" [String] keys to the images grains of the document
    #   * "files" [String] keys to the files grains of the document
    #
    # @example
    #   nsicloudooo.grains_keys_for("some key")
    def grains_keys_for(document_key)
      request = prepare_request :GET, {:doc_key => document_key}.to_json
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
