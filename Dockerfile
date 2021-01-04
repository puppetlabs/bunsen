FROM node:lts-alpine
MAINTAINER community@puppet.com

# Install hubot dependencies
RUN apk update\
 && apk upgrade\
 && apk add jq\
 && npm install -g yo generator-hubot@next\
 && rm -rf /var/cache/apk/*

# Create hubot user with privileges
RUN addgroup -g 501 hubot\
 && adduser -D -h /hubot -u 501 -G hubot hubot
ENV HOME /home/hubot
WORKDIR $HOME
RUN chown -R hubot:hubot .
USER hubot

RUN yo hubot\
 --adapter=slack\
 --owner="Puppet Community <community@puppet.com>"\
 --name="bunsen"\
 --description="Freeing you to do what the robots can't."\
 --defaults

COPY scripts/* /home/hubot/scripts/
COPY external-scripts.json /home/hubot

# Add any npm scripts to install here
RUN npm install --save clark @slack/interactive-messages cron

EXPOSE 80

CMD ["bin/hubot", "--adapter", "slack"]
