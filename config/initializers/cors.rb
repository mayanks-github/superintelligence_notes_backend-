Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(
      "http://localhost:5173",
      "http://127.0.0.1:5173",
      /chrome-extension:\/\/.*/
    )

    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: [ "Authorization" ]
  end
end
