// Description
//   A hubot wrapper for @slack/interactive-messages.
//
// Configuration:
//   SLACK_SIGNING_SECRET, SLACK_ACTIONS_URL, SLACK_OPTIONS_URL
// Commands
//
// Notes:
//
// Author:
//   Farid Nouri Neshat <FaridN_SOAD@Yahoo.com>
//   https://gitlab.olindata.com/olindata/hubot-interactive-messages/

'use strict';

const { createMessageAdapter } = require('@slack/interactive-messages');

module.exports = function (robot) {
  if (robot.setActionHandler || robot.setOptionsHandler) {
    throw new Error(`robot.setActionHandler and robot.setOptionsHandler are already defined.
This module will not redefine them. Something is conflicting with this module.`);
  }

  const slackMessages = createMessageAdapter(process.env.SLACK_SIGNING_SECRET);

  robot.setActionHandler = slackMessages.action.bind(slackMessages);
  robot.setOptionsHandler = slackMessages.options.bind(slackMessages);

  const messageMiddleware = slackMessages.expressMiddleware();

  robot.router.use(process.env.SLACK_ACTIONS_URL || '/slack/actions', messageMiddleware);
  robot.router.use(process.env.SLACK_OPTIONS_URL || '/slack/options', messageMiddleware);
};
