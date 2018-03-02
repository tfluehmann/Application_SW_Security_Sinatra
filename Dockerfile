FROM ruby:2.5.0

ENV ENVIED_ENABLE_DEFAULTS=true

# fixes: https://github.com/bundler/bundler/issues/4576
RUN gem install bundler

# we serve in localtime
RUN echo Europe/Zurich | tee /etc/timezone

ENV HOME /usr/src/app
WORKDIR ${HOME}

ADD Gemfile Gemfile.lock ${HOME}/
RUN bundle install --jobs 4

ADD . ${HOME}/
EXPOSE 4567

CMD ["bundle", "exec", "rackup", "config.ru", "-p", "4567", "-s", "puma", "-o", "0.0.0.0"]
