# Description:
#   Automatically post Puppet Forge links when module names are seen
#
# Commands:
#   forge search <query> - Links the top module results from the Forge
#
# Notes:
#   None
#
# Author:
#   Ben Ford <ben.ford@puppet.com>

base_url     = "https://forge.puppet.com"
query_url    = "https://forgeapi.puppet.com/v3/modules"
query_params = "hide_deprecated=true&limit=3&module_groups=base pe_only&query"
slug_regex   = /\b(\w+)[-\/](\w+)\b/
search_regex = /^forge search (.*)/

module.exports = (robot) ->

  robot.hear slug_regex, (msg) ->
    author = msg.match[1]
    name   = msg.match[2]
    msg
      .http("#{query_url}/#{author}-#{name}")
      .get() (err, res, body) =>

        mod = JSON.parse(body)
        if mod.owner?
          robot.adapter.client.web.conversations.list()
            .then (api_response) ->
              found = api_response.channels.find (iter) -> iter.id is msg.message.room
              channel = if found? then found.name else msg.message.room
              msg.send "See the `#{mod.slug}` module at #{base_url}/#{mod.owner.username}/#{mod.name}?src=slack&channel=#{channel}"


  robot.hear search_regex, (msg) ->
    query = msg.match[1]
    msg
      .http(encodeURI("#{query_url}?#{query_params}=#{query}"))
      .get() (err, res, body) =>

        response = JSON.parse(body)
        if response.pagination.total > 0
          robot.adapter.client.web.conversations.list()
            .then (api_response) ->
              found = api_response.channels.find (iter) -> iter.id is msg.message.room
              channel = if found? then found.name else msg.message.room

              str = response.results.reduce (str, mod) ->
                str.concat "- #{base_url}/#{mod.owner.username}/#{mod.name}?src=slack&channel=#{channel}\n"
              , ''

              msg.send str.concat "<#{base_url}/modules?q=#{query}|See all #{response.pagination.total} results on the Forge>."

        else
          msg.send "No Forge modules found for that query."
