require 'yajl'
require 'rack/body_proxy'

module Rack
  # The following code is a modified version of Rack::CommonLogger
  # Copyright (c) 2007, 2008, 2009, 2010, 2011, 2012 Christian Neukirchen <purl.org/net/chneukirchen>
  # https://github.com/rack/rack
  #
  # Rack::JsonCommonLogger forwards every request to an +app+ given, and
  # logs a JSON line in the Apache common log format to the +logger+, or
  # rack.errors by default. It is also possible to pass a block to perform
  # custom processing on the Hash object that will be then converted to JSON.
  class JsonCommonLogger
    def initialize(app, logger=nil, &custom_log)
      @app = app
      @logger = logger
      @custom_log = custom_log
    end

    def call(env)
      began_at = Time.now
      status, header, body = @app.call(env)
      header = Utils::HeaderHash.new(header)
      body = BodyProxy.new(body) { log(env, status, header, began_at) }
      [status, header, body]
    end

    private

    def log(env, status, header, began_at)
      now = Time.now
      length = extract_content_length(header)

      logger = @logger || env['rack.errors']
      body = env["rack.input"].read

      @db = Thread.current
      if (env["PATH_INFO"] != '/ping-fstrz')
        log = {
          :host => env['HTTP_X_FORWARDED_FOR'] || env["REMOTE_ADDR"] || "-",
          :user => env["REMOTE_USER"] || "-",
          :method => env["REQUEST_METHOD"],
          :path => env["PATH_INFO"],
          :query => env["QUERY_STRING"].empty? ? "" : "?"+env["QUERY_STRING"],
          :body_data => body.empty? ? "" : body,
          :version => env["HTTP_VERSION"],
          :status => status.to_s[0..3],
          :length => length,
          :duration => now - began_at,
          :request_id => @db[:request_id],
          :log_level => 'INFO',
          :message => "#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}#{env["QUERY_STRING"].empty? ? "" : "?"+env["QUERY_STRING"]} #{status.to_s[0..3]} #{now - began_at}"
        }

        log = @custom_log.call(log, status, header, env) if @custom_log

        logger.write(Yajl::Encoder.encode(log))
        logger.write("\n")
      end
    end

    def extract_content_length(headers)
      value = headers['Content-Length'] or return '-'
      value.to_s == '0' ? '-' : value
    end
  end
end
