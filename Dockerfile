FROM ruby:2.2.0

RUN apt-get update -qq && apt-get install -y build-essential

RUN mkdir -p /ambroi-messenger

WORKDIR /ambroi-messenger

ADD Gemfile /ambroi-messenger/Gemfile
ADD Gemfile.lock /ambroi-messenger/Gemfile.lock
RUN bundle install

ADD . /ambroi-messenger

