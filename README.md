# Dr Bunsen Honeydew
## Slack bot extraordinaire, at your service.

This is a simple Slackbot, based on [hubot](https://hubot.github.com), and the
k8s config required to stand him up.

### Customization

There are two ways to customize this bot. The simplest is just to add existing
scripts from the [NPM registry](https://www.npmjs.com/browse/keyword/hubot-scripts).

1. Find the script you want and learn how to configure it.
    * Environment variables will go in `k8s/deployment.yaml`.
1. Add the name of the script to `external-scripts.json`.
1. Add the script and any dependencies to the `npm install` call in the `Dockerfile`.

You can also *write* a custom script.

1. Write the script in the `scripts` directory.
    * Don't add this to `external-scripts.json`, that happens automatically.
1. Add any dependencies to the `npm install` call in the `Dockerfile`.
1. Add any environment variables needed to `k8s/deployment.yaml`.

### Building and testing

* Build the image with `rake docker:build`.
* Run the bot locally for testing with `rake docker:run`. This will drop you into
  a shell bot simulator where you can "direct message" with the bot.
* If you need filesystem access, you can run the image directly:
    * `docker run -it puppetlabs/bunsen /bin/sh`
    * Start the shell with `bin/hubot`

### Publishing

This requires push access to the `puppet-community` GCR namespace. Setting that
up is out of scope for this document. You'll also need to be a slack admin to
recycle the bot.

1. `rake docker:push`
1. Wait 30 seconds
1. In slack: `@bunsen restart`

Yes, this process will be improved shortly.
