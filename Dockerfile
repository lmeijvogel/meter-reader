FROM ruby:3.0.1-buster

ENV TZ=Europe/Amsterdam
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && \
    apt-get install tini && \
    rm -rf /var/lib/apt/lists/*

RUN useradd --uid 1000 --home-dir /app api

WORKDIR /app

COPY Gemfile* /app/

RUN bundle config set --local path '/bundle'
RUN bundle install

USER api

COPY * /app/

WORKDIR /app/webapp

ENTRYPOINT ["tini", "--"]
CMD ["bundle", "exec", "ruby", "energie_api.rb", "--port 9292"]
