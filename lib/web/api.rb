module Web
  class Api
    def call(environment)
      response(
        body: ["hi"]
      )
    end

    private

    def response(status: 200, headers: {}, body: [])
      [
        status,
        headers,
        body
      ]
    end
  end
end
