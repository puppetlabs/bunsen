# Description:
#   Automatically post Puppet Forge links when module names are seen
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   None
#
# Notes:
#   None
#
# Author:
#   Ben Ford <ben.ford@puppet.com>

base_url  = "https://forge.puppet.com"
query_url = "https://forgeapi.puppet.com/v3/modules"
regex     = /\b(\w+)[-\/](\w+)\b/

module.exports = (robot) ->

  robot.hear regex, (msg) ->
    author = msg.match[1]
    name   = msg.match[2]

    msg
      .http("#{query_url}/#{author}-#{name}")
      .get() (err, res, body) =>

        mod = JSON.parse(body)
        if mod.owner?
          channel = msg['message']['room']
          msg.send "See the `#{mod.slug}` module at #{base_url}/#{mod.owner.username}/#{mod.name}?src=slack&channel=#{channel}"
