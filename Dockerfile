FROM ruby:3.0.1-buster

ENV TZ=Europe/Amsterdam
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /app

COPY Gemfile* /app/

RUN bundle config set --local path '/bundle'
RUN bundle install

COPY * /app/

WORKDIR /app/webapp

CMD bundle exec ruby energie_api.rb -p 9292
