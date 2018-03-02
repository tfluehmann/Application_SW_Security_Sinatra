FROM ruby:2.4.2

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
ENV PORT 3000
EXPOSE 3000

CMD ruby app.rb
