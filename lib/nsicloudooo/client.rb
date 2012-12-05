require "json"
require "net/http"
require File.dirname(__FILE__) + '/errors'
require File.dirname(__FILE__) + '/configuration'

module NSICloudooo
  class Client

    # Initialize a client to a CloudoooManager node
    #
    # @param [Hash] options used to connect to the desired CloudoooManager
    # @options options [String] host to connect
    # @options options [String] port to connect
    # @options options [String] user to authenticatie with
    # @options options [String] password to the refered user
    #
    # @return [Client] the object itself
    # @example
    #   nsisam = NSISam::Client.new host: 'localhost', port: '8886', user: 'test', password: 'test'
    #
    # @note if you had used the 'configure' method, you can use it without parameters
    #       and those you provided before will be used (see Client#configure)
    def initialize(params = {})
      params = Configuration.settings.merge(params)
      @user = params[:user]
      @password = params[:password]
      @host = params[:host]
      @port = params[:port]
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
    #   require 'base64'
    #   doc = Base64.encode64(File.new('document.odt', 'r').read)
    #   response = nsicloudooo.granulate(:file => doc, :filename => 'document.odt')
    #   nsicloudooo.done(response["doc_key"])
    #   nsicloudooo.grains_keys_for(response["doc_key"])
    # @example Granulating from a SAM uid
    #   doc = Base64.encode64(File.new('document.odt', 'r').read)
    #   response = sam.store({:doc => doc})
    #   doc_key = response["doc_key"]
    #   response = nsicloudooo.granulate(:sam_uid => doc_key, :filename => 'document.odt')
    #   nsicloudooo.done(response["doc_key"])
    #   nsicloudooo.grains_keys_for(response["doc_key"])
    # @example Downloading and granulating from web
    #   response = nsicloudooo.granulate(:doc_link => 'http://google.com/document.odt')
    #   nsicloudooo.done(response["doc_key"])
    #   nsicloudooo.grains_keys_for(response["doc_key"])
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
    #
    # @raise NSICloudooo::Errors::Client::MissingParametersError when an invalid or incomplete set of parameters is provided
    # @raise NSICloudooo::Errors::Client::SAMConnectionError when cannot connect to the SAM node
    # @raise NSICloudooo::Errors::Client::AuthenticationError when invalids user and/or password are provided
    # @raise NSICloudooo::Errors::Client::KeyNotFoundError when an invalid sam_uid is provided
    #
    def granulate(options = {})
      @request_data = Hash.new
      if options[:doc_link]
        insert_download_data options
      elsif options[:sam_uid] && options[:filename]
        file_data = {:sam_uid => options[:sam_uid], :filename => options[:filename]}
        @request_data.merge! file_data
      elsif options[:file] && options[:filename]
        file_data = {:doc => options[:file], :filename => options[:filename]}
        @request_data.merge! file_data
      else
        raise NSICloudooo::Errors::Client::MissingParametersError
      end
      insert_callback_data options
      request = prepare_request :POST, @request_data.to_json
      execute_request(request)
    end

    # Verify if a document is already granulated
    #
    #
    # @param [String] key of the desired document
    # @return [Hash] response
    #   * "done" [String] true if the document was already granualted, otherwise, false
    #
    # @example
    #   nsicloudooo.done("some key")
    #
    # @raise NSICloudooo::Errors::Client::SAMConnectionError when cannot connect to the SAM node
    # @raise NSICloudooo::Errors::Client::AuthenticationError when invalids user and/or password are provided
    # @raise NSICloudooo::Errors::Client::KeyNotFoundError when an invalid key is provided
    #
    def done(key)
      request = prepare_request :GET, {:key => key}.to_json
      execute_request(request)
    end

    # Return the keys of the grains of a document
    #
    #
    # @param [String] key of the desired document
    # @return [Hash] response
    #   * "images" [String] keys to the images grains of the document
    #   * "files" [String] keys to the files grains of the document
    #
    # @example
    #   nsicloudooo.grains_keys_for("some key")
    #
    # @raise NSICloudooo::Errors::Client::SAMConnectionError when cannot connect to the SAM node
    # @raise NSICloudooo::Errors::Client::AuthenticationError when invalids user and/or password are provided
    # @raise NSICloudooo::Errors::Client::KeyNotFoundError when an invalid key is provided
    #
    def grains_keys_for(document_key)
      request = prepare_request :GET, {:doc_key => document_key}.to_json
      execute_request(request).select {|chave| ['images', 'files'].include? chave}
    end

    # Return the key of the thumbnail of a document
    #
    #
    # @param [String] key of the desired document
    # @return [String] key of the desired document's thumbnail
    #
    # @example
    #   nsicloudooo.thumbnail_key_for("some key")
    #
    # @raise NSICloudooo::Errors::Client::SAMConnectionError when cannot connect to the SAM node
    # @raise NSICloudooo::Errors::Client::AuthenticationError when invalids user and/or password are provided
    # @raise NSICloudooo::Errors::Client::KeyNotFoundError when an invalid key is provided
    #
    def thumbnail_key_for(document_key)
      request = prepare_request :GET, {:doc_key => document_key}.to_json
      execute_request(request)["thumbnail"]
    end


    # Enqueue a document to have its metadata extracted
    #
    #
    # @param [String] key of the desired document
    # @param [String] type of the desired document ('tcc' or 'event')
    # @return [Hash] response
    #   * "doc_key" [String] the key to access the granulated document if the sam node it was stored
    #
    # @raise NSICloudooo::Errors::Client::MissingParametersError when an invalid or incomplete set of parameters is provided
    # @raise NSICloudooo::Errors::Client::SAMConnectionError when cannot connect to the SAM node
    # @raise NSICloudooo::Errors::Client::AuthenticationError when invalids user and/or password are provided
    # @raise NSICloudooo::Errors::Client::KeyNotFoundError when an invalid sam_uid is provided
    #
    def extract_metadata(document_key, type, callback_url=nil, callback_verb=nil)
      @request_data = {:sam_uid => document_key, :type => type, :metadata => true}
      insert_callback_data {:callback => callback_url, :verb => callback_verb}
      request = prepare_request :POST, @request_data.to_json
      execute_request(request)
    end

    # Return the key of the metadata of a document
    #
    #
    # @param [String] key of the desired document
    # @return [String] key of the desired document's metadata or false if the metadata wasn't extracted yet
    #
    # @example
    #   nsicloudooo.metadata_key_for("some key")
    #
    # @raise NSICloudooo::Errors::Client::SAMConnectionError when cannot connect to the SAM node
    # @raise NSICloudooo::Errors::Client::AuthenticationError when invalids user and/or password are provided
    # @raise NSICloudooo::Errors::Client::KeyNotFoundError when an invalid key is provided
    #
    def metadata_key_for(document_key)
      request = prepare_request :GET, {:doc_key => document_key, :metadata => true}.to_json
      execute_request(request)["metadata_key"]
    end

    # Pre-configure the NSICloudooo module with default params for the NSICloudooo::Client
    #
    # @yield a Configuration object (see {NSICloudooo::Client::Configuration})
    #
    # @example
    #   NSICloudooo::Client.configure do
    #     user     "why"
    #     password "chunky"
    #     host     "localhost"
    #     port     "8888"
    #   end
    def self.configure(&block)
      Configuration.instance_eval(&block)
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
      begin
        response = Net::HTTP.start @host, @port do |http|
          http.request(request)
        end
      rescue Errno::ECONNREFUSED => e
        raise NSICloudooo::Errors::Client::ConnectionRefusedError
      else
        raise NSICloudooo::Errors::Client::KeyNotFoundError if response.code == "404"
        raise NSICloudooo::Errors::Client::MalformedRequestError if response.code == "400"
        raise NSICloudooo::Errors::Client::AuthenticationError if response.code == "401"
        raise NSICloudooo::Errors::Client::QueueServiceConnectionError if response.code == "503"
        if response.code == "500" and response.body.include?("SAM")
          raise NSICloudooo::Errors::Client::SAMConnectionError
        end
        JSON.parse(response.body)
      end
    end
  end
end
