FROM ruby:3.1.1-alpine

RUN \
apk update \
&& apk upgrade \
&& apk --no-cache add ruby ruby-dev ruby-bundler ruby-json ruby-irb ruby-rake ruby-bigdecimal \
&& apk --no-cache add make g++ \
&& rm -rf /var/cache/apk/*

WORKDIR /codepraise

COPY / .

RUN bundle install --without=test development

CMD bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}