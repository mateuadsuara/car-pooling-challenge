require 'cgi'

module Web
  class FormParser
    def self.parse_id(request)
      if (request.content_type&.downcase != "application/x-www-form-urlencoded")
        raise StandardError.new("expected content type to be form urlencoded")
      end

      body = request.body.gets

      begin
        params = CGI::parse(body)
        ids = params["ID"]
      rescue
      end

      raise StandardError.new("expected one ID x-www-form-urlencoded parameter") unless ids&.length == 1

      begin
        id = Integer(ids.first)
      rescue
        raise StandardError.new("expected ID to be an integer")
      end

      id
    end
  end
end
