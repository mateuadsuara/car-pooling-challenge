require 'rack'

module Web
  class Api
    include Rack

    def call(environment)
      request = Request.new(environment)
      response = handle(request)
      response.finish
    end

    def handle(request)
      if request.get? && request.path_info == "/status"
        return Response.new("ready", 200)
      end

      Response.new(nil, 404)
    end
  end
end
