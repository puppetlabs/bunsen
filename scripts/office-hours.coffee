# Description:
#   Puppet Community Office Hours
#
# Commands:
#   none
#
# Author:
#   Ben Ford <ben.ford@puppet.com>

CronJob = require('cron').CronJob
calendarUrl = "https://www.googleapis.com/calendar/v3/calendars/puppet.com_1bv1p3pc433btsejtm5hikhmec@group.calendar.google.com/events"
main_channel = 'apptesting'
office_hours = 'apptesting'

module.exports = (robot) ->
  # Resolve channel names to IDs
  robot.adapter.client.web.conversations.list()
    .then (api_response) ->
      room = api_response.channels.find (channel) -> channel.name is main_channel
      main_channel = room.id if room?

      room = api_response.channels.find (channel) -> channel.name is office_hours
      office_hours = room.id if room?

  registerJob = (expr, cb) ->
    new CronJob expr, cb, null, true

  timeLink = (dt) ->
    timestamp = dt.toISOString().replace(/[-:Z]|(.000)/g,'')
    # the p1,2,3 elements are locations. Modify the list by adding locations via the web and observing the URL changes
    "https://www.timeanddate.com/worldclock/converter.html?iso=#{timestamp}&p1=202&p2=919&p3=307&p4=3332&p5=236&p6=240"

  getNextSession = (cb) ->
    robot.http(calendarUrl)
      .query
        key: process.env.GOOGLE_CALENDAR_APIKEY
        maxResults: 1
        singleEvents: true
        orderBy: 'startTime'
        timeMin: new Date().toISOString()
      .get() (err, res, body) ->
        data = JSON.parse(body)
        cb data.items[0]

  getUpcomingSession = (cb) ->
    now  = new Date()
    next = new Date()
    now.setMinutes(now.getMinutes() + 15)
    next.setMinutes(now.getMinutes() + 30)

    robot.http(calendarUrl)
      .query
        key: process.env.GOOGLE_CALENDAR_APIKEY
        maxResults: 1
        singleEvents: true
        orderBy: 'startTime'
        timeMin: now.toISOString()
        timeMax: next.toISOString()
      .get() (err, res, body) ->
        data = JSON.parse(body)
        if data.items.length != 0
          cb data.items[0]

  registerJob '0 45 * * * *', ->
    getUpcomingSession (event) ->
      start  = new Date(event.start.dateTime)
      finish = new Date(event.end.dateTime)

      minsToStart = Math.round((start - Date.now())/(1000*60)) # human readable
      msToFinish  = Math.round(finish - Date.now())            # machine readable

      robot.messageRoom(main_channel, "_#{event.summary}_ is about to start up in #office-hours")
      robot.messageRoom(office_hours, "_#{event.summary}_ is about to start up in #{minsToStart} minutes")

      setTimeout ->
        getNextSession (event) ->
          start      = new Date(event.start.dateTime)
          hrsToStart = Math.round((start - Date.now())/(1000*60*60)) # human readable
          if hrsToStart > 0
            robot.messageRoom(office_hours, { text: "Next up is _#{event.summary}_ in <#{timeLink start}|#{hrsToStart} hours>", unfurl_links: false })

#          # This method is not allowed for bots belonging to a slack app. https://api.slack.com/methods/conversations.setTopic
#          robot.adapter.client.web.conversations.setTopic(office_hours, "Next up is _#{event.summary}_ at <#{timeLink start}|#{start.toUTCString()}>")
      , msToFinish


  robot.hear /next office hour.*\?/i, (msg) ->
    getNextSession (event) ->
      start  = new Date(event.start.dateTime)
      hrsToStart = Math.round((start - Date.now())/(1000*60*60)) # human readable
      msg.send({ text: "The next Office Hour is _#{event.summary}_ in <#{timeLink start}|#{hrsToStart} hours> in #office-hours", unfurl_links: false })

