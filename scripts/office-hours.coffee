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
main_channel = 'puppet'
office_hours = 'office-hours'

module.exports = (robot) ->
  # Resolve channel names to IDs. Check for a client first so we can run via shell for testing
  if robot.adapter.client
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

  emoji = ->
    items = [
      ':coffee:',
      ':kermit_typing:',
      ':the_more_you_know:',
      ':beaker:',
      ':businessparrot:',
      ':fry_dancing:',
      ':goodnews:',
      ':indeed:',
      ':letsplay:',
      ':meeting:',
      ':allthethings:',
      ':waiting:'
    ]
    items[~~(items.length * Math.random())]

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
    now  = new Date(new Date().getTime() + 15*60000)
    next = new Date(new Date().getTime() + 30*60000)

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
    robot.logger.info "Checking for upcoming Office Hours..."
    getUpcomingSession (event) ->
      robot.logger.info " ↳ posting event info"
      start  = new Date(event.start.dateTime)
      finish = new Date(event.end.dateTime)

      minsToStart = Math.round((start - Date.now())/(1000*60)) # human readable
      msToFinish  = Math.round(finish - Date.now())            # machine readable

      robot.messageRoom(main_channel, "#{emoji()} _#{event.summary}_ is about to start up in #office-hours")
      robot.messageRoom(office_hours, "#{emoji()} _#{event.summary}_ is about to start up in #{minsToStart} minutes")

      setTimeout ->
        robot.logger.info " ↳ session finishing up, checking for the next one..."
        getNextSession (event) ->
          start      = new Date(event.start.dateTime)
          hrsToStart = Math.round((start - Date.now())/(1000*60*60)) # human readable
          if hrsToStart > 0
            robot.messageRoom(office_hours, { text: "#{emoji()} Next up is _#{event.summary}_ in <#{timeLink start}|#{hrsToStart} hours>", unfurl_links: false })

#          # This method is not allowed for bots belonging to a slack app. https://api.slack.com/methods/conversations.setTopic
#          robot.adapter.client.web.conversations.setTopic(office_hours, "#{emoji} Next up is _#{event.summary}_ at <#{timeLink start}|#{start.toUTCString()}>")
      , msToFinish


  robot.hear /next office hour.*\?/i, (msg) ->
    getNextSession (event) ->
      start  = new Date(event.start.dateTime)
      hrsToStart = Math.round((start - Date.now())/(1000*60*60)) # human readable
      msg.send({ text: "#{emoji()} The next Office Hour is _#{event.summary}_ in <#{timeLink start}|#{hrsToStart} hours> in #office-hours", unfurl_links: false })

