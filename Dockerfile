FROM ruby:3.2.2

WORKDIR /opt/car-pooling-challenge

# Copy the dependency definitions and install before copying everything else
# so we can cache this layer and reuse it everytime we change the rest.
# This translates in faster development as this step changes less frequently.
COPY ./Gemfile /opt/car-pooling-challenge
COPY ./Gemfile.lock /opt/car-pooling-challenge
RUN bundle install

COPY . /opt/car-pooling-challenge

ENV PORT=9091
EXPOSE 9091
ENTRYPOINT [ "/opt/car-pooling-challenge/start-api" ]
