FROM ruby:2.7-alpine
WORKDIR /challenge
COPY . .
RUN gem install minitest
CMD ["ruby", "customer_success_balancing.rb"]
