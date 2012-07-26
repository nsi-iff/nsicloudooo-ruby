require "logger"
require "sinatra"
require "json"
require "thread"

module NSICloudooo
  class Server < Sinatra::Application

    def self.prepare
      @@done = Hash.new
    end

    post "/" do
      content_type :json
      incoming = JSON.parse(request.body.read)
      filename = incoming["filename"]
      filename = File.basename(incoming["doc_link"]) if incoming.has_key? "doc_link"
      callback = incoming["callback"] || nil
      verb = incoming["verb"] || nil
      if filename.include? "secs"
        seconds = filename.split(".")[0].delete("secs").to_i
        sleep seconds-1
      elsif filename.include? "queue error"
        return 503
      end
      {
        doc_key: "key for document #{filename}",
        callback: callback,
        verb: verb,
      }.to_json
    end

    get "/" do
      content_type :json
      incoming = JSON.parse(request.body.read)
      if incoming.has_key?("key") && incoming["key"].include?("secs")
        unless @@done.has_key? incoming["key"]
          @@done[incoming["key"]] = true
          return {done: false}.to_json
        else
          return {done: true}.to_json
        end
      elsif incoming.has_key? "doc_key"
        return {:images => [], :files => [], :thumbnail => ['thumbnail key',]}.to_json
      end
    return 404 if incoming["key"].include? "dont"
    end
  end

  class FakeServerManager

    # Start the nsi.cloudooo fake server
    #
    # @param [Fixnum] port the port where the fake server will listen
    #   * make sure there's not anything else listenning on this port
    def start_server(port=9886)
      @thread = Thread.new do
        Server.prepare
        Server.run! :port => port
      end
      sleep(1)
      self
    end

    # Stop the SAM fake server
    def stop_server
      @thread.kill
      self
    end
  end
end
