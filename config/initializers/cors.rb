Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "localhost:4200",
            "localhost:4201",
            "localhost:4202",
            "https://sandbox-app1-fe.sakuramobile.jp",
            "https://sandbox-app2-fe.sakuramobile.jp"
    # origins Settings.cors.origins
    resource "*", :headers => :any, :methods => %i[get post put patch delete options head], :credentials => true
  end
end
