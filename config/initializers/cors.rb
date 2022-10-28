Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:4200',
            'localhost:4201',
            'localhost:4202',
            'localhost:4211',
            'localhost:3001',
            'https://www.sakuramobile.jp',
            'https://my.sakuramobile.jp',
            'https://operation.sakuramobile.jp',
            'https://myaccount.sakuramobile.jp',
            'https://longterm-order.sakuramobile.jp',
            'https://parental-consent.sakuramobile.jp',
            'https://fiber-order.sakuramobile.jp',
            'https://stg-myaccount.sakuramobile.jp',
            'https://stg-longterm-order.sakuramobile.jp',
            'https://stg-parental-consent.sakuramobile.jp',
            'https://stg-fiber-order.sakuramobile.jp',
            'https://rc-myaccount.sakuramobile.jp',
            'https://rc-longterm-order.sakuramobile.jp',
            'https://rc-parental-consent.sakuramobile.jp',
            'https://rc-fiber-order.sakuramobile.jp'
    # origins Settings.cors.origins
    resource '*', :headers => :any, :methods => [:get, :post, :put, :patch, :delete, :options, :head], credentials: true
  end
end
