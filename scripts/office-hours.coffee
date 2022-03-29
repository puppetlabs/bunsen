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
    "https://www.timeanddate.com/worldclock/converter.html?iso=#{timestamp}&p1=202&p2=179&p3=919&p4=307&p5=3332&p6=236&p7=240"

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

  # unbounded next event, no matter how far out
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

  # time bounded, get an event within a range of minutes from now
  getUpcomingSession = (cb, now = 15, next = 30) ->
    now  = new Date(new Date().getTime() + now*60000)
    next = new Date(new Date().getTime() + next*60000)

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

  setSessionTimeout = (event) ->
    # Kick in shortly after the session finishes to make sure it's done.
    msToFinish = new Date(event.end.dateTime) - Date.now() + 2*60000

    setTimeout ->
      robot.logger.info " ↳ session finishing up, checking for the next one..."
      getNextSession (event) ->
        start      = new Date(event.start.dateTime)
        hrsToStart = Math.round((start - Date.now())/(1000*60*60))

        # if there's not a currently running session...
        if hrsToStart > 0
          robot.messageRoom(office_hours, {
            text: "#{emoji()} Next up is _#{event.summary}_ in <#{timeLink start}|#{hrsToStart} hours>",
            unfurl_links: false
          })

          # This method is not allowed for bots belonging to a slack app. https://api.slack.com/methods/conversations.setTopic
          #robot.adapter.client.web.conversations.setTopic(office_hours, "#{emoji} Next up is _#{event.summary}_ at <#{timeLink start}|#{start.toUTCString()}>")
    , msToFinish


  # if we restart in the middle of a session, this will recover the end of session timeout
  # The super short time range should only return events running during that one minute
  robot.logger.info "Checking for a running session..."
  getUpcomingSession (event) ->
    robot.logger.info " ↳ setting timeout"
    setSessionTimeout event
  , 0, 1

  registerJob '0 15,45 * * * *', ->
    robot.logger.info "Checking for upcoming Office Hours..."
    getUpcomingSession (event) ->
      robot.logger.info " ↳ posting event info"
      start       = new Date(event.start.dateTime)
      minsToStart = Math.round((start - Date.now())/(1000*60))

      robot.messageRoom(main_channel, "#{emoji()} _#{event.summary}_ is about to start up in #office-hours")
      robot.messageRoom(office_hours, "#{emoji()} _#{event.summary}_ is about to start up in #{minsToStart} minutes")

      setSessionTimeout event


  robot.hear /next office hour.*\?/i, (msg) ->
    getNextSession (event) ->
      start      = new Date(event.start.dateTime)
      hrsToStart = Math.round((start - Date.now())/(1000*60*60))

      if hrsToStart < 0
        content = "#{emoji()} _#{event.summary}_ is running right now in #office-hours!"
      else
        content = "#{emoji()} The next Office Hour is _#{event.summary}_ in <#{timeLink start}|#{hrsToStart} hours> in #office-hours"

      # send rich content so slack doesn't unfurl the time zone page
      if robot.adapter.client
        msg.send({ text: content, unfurl_links: false })
      else
        msg.send content

