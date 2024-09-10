# [Backstage](https://backstage.io)

To run locally you need a Node version 18 or 20 available with `yarn` installed. Typically you'd use a utility like `nvm` or `nodenv` to install Node, set that version active, then use NPM to install `yarn`

To start the app, run:

```sh
yarn setup
yarn install
yarn dev
```

## A few technical details

* The `yarn setup` step has been added for a bit of developer utility, including shipped templates for `.env` and the `app-config.local.yaml` file Backstage looks for automatically on local-only execution
  * Note: This seems to still have OS-specific trouble at times. The extras can be torn out of `package.json` with the user just copying the two files manually. The token part is not in use yet.
  * `yarn minisetup` can be used to skip the token and env loading - but be mindful what'll be missing or adjust as needed for your sytem
* The `packages/backend/Dockerfile` remains unmodified as of this writing and works - optimization in a multi-layered build can come later. It starts in `/app` meaning links to local catalog files need to look there, not in `../..` as is done when running from source
  * Instructions for building Docker are available within the Dockerfile
* The included `Jenkinsfile` can successfully build and publish the Docker image when paired with a compatible Jenkins setup (targets Google Container Registry, easy to change)
* There is a separate infra repo at https://github.com/CervTest/backstage-infra with another Jenkinsfile that knows how to deploy to a public demo Backstage via Helm
  * This further supports secrets imported via Jenkins credentials and a `cm-app-config.extra.yaml` that is supplied in a Kubernetes context and wired up for the Backstage container without further config or rebuild needed 

## Plugins

For Backstage plugins have traditionally been applied directly to source code, while also relying on a Node dependency. As such it has been tricky to "install" a bunch of plugins quickly, as each takes modifying source files, often overlapping. One approach to at least _seeing_ how individual plugins work is making a new branch off `basic` then solely installing a single plugin there. Later instance branches (like `main`) that correspond to a given Backstage can be merged into from various plugin branches with any conflicts resolved then.

While working locally with this approach it is important to keep your config files and .gitignored files in mind, lest you end up with a plugin and a half if for instance `app-config.local.yaml` has not been deleted. The `.env` file will also not overwrite when running `yarn setup` again, but then generally won't cause trouble from having more new variables added than needed.

To validate your plugin after following the instructions run `yarn install` then `yarn tsc` and consider adjusting the locally included `catalog-info.yaml` with an appropriate annotation to test. You might also want to minimize extra tweaks to whitespace and the like to leave a clearer overview and make it easier to merge plugin branches around without causing excessive conflicts (make such edits in the relevant base branch instead)

For managing secrets on the GitHub/Jenkins/GCP setup make the associated credential in Jenkins and then reference it in the `backstage-infra` repo. In there the `Jenkinsfile` will load the credential, write it into a Kubernetes secrets file locally, which is then deployed to k8s and loaded by Backstage as extra environment variables you can then simply reach normally in config. Note that there is also an additional extra override config file in the infra repo, much like the local config file when working in a developer workspace.

### SkillExchange

This plugin from Spotify's premium plugin bundle enables a series of skill-oriented functionality in Backstage. See its [documentation page](https://backstage.spotify.com/docs/plugins/skill-exchange/) and [install page](https://backstage.spotify.com/docs/plugins/skill-exchange/setup-and-installation) for details.

Some needed steps from the docs:

* (actually get Backstage running from source with basic GitHub integration/auth)
* Make sure backend auth works
* Make sure we have user entities (ideally via the GitHub auth sign-in resolver)
* Slack integration? This may be optional and something we could defer. Rasmus has a Slack instance that could be used if needed (it may take a bit to get integrated into the live Adaptavist Slack)
* Install the Backend plugin (avoid the new backend system if using the GitHub setup - it sits on an older Backstage version still)
* Come up with some skill lists - public demo data should be available or we could dream some up! Can be silly, Rasmus might bring his newborn's skills in for visualizing ...
* Something about a Hack Digest notification on Slack - this sounds relevant to our interests but we should probably get other stuff working first and examine what Hacks cover
* Install the Frontend plugin

Then what we hope to add:

* Add some Hack entries that match real live Hackathon entries from the 2024 Adaptavist Hackday!
* Look for options for how we can group some Hack entities together in a Hackday event
* Possibly add custom functionality to achieve the above and/or go further like adding a voting system
* Prep a presentation for what got done!

#### Steps taken

A running tally of what's been done

* Confirmed deployments still work and set the `skillexchange` branch to be active
* Updated the Spotify license secret
* `yarn workspace backend add @spotify/backstage-plugin-skill-exchange-backend`
* Added `packages/backend/src/plugins/skillexchange.ts` with content from install instructions
* Added lines to `packages/backend/src/index.ts` as per docs
* Added lines to `packages/backend/src/search.ts` as per docs
* `yarn workspace app add @spotify/backstage-plugin-skill-exchange`
* Added to `packages/app/src/App.tsx`
* Added to `packages/app/src/components/Root/Root.tsx`
* Added to `packages/app/src/components/catalog/EntityPage.tsx`
* Added the Spotify license block to app-config.yaml (having a SPOTIFY_LICENSE env var available):

```
spotify:
  licenseKey: ${SPOTIFY_LICENSE}
```

So far so good! The above made UI elements visible in the app, and with the license key set right also avoided a banner about not being licensed. Nothing API-related worked though, so probably can't skip by https://backstage.io/docs/auth/service-to-service-auth--old ! (note: still using old backend)

* Adjust `packages/backend/src/index.ts` to enable the validation token thing
* Add the backend secret (env var) and use it in `app-config.yaml`

Oddly while the SkillExchange docs pointed to the old backend option for the _token_ handling it did not link to https://github.com/backstage/backstage/blob/master/contrib/docs/tutorials/authenticate-api-requests.md which talks about API auth itself. That changes majorly with 1.26 but as of this writing this repo uses 1.21 so lets give it a try!

* Create `packages/backend/src/authMiddleware.ts`
* `yarn --cwd packages/backend add cookie-parser`
* Update `packages/backend/src/index.ts` further with some cookie auth thing
* ~~Create `packages/app/src/cookieAuth.ts`~~ - actually, this ended up just embedding a slightly different version from https://gitlab.adaptavist.net/backstage/clients/adaptavist/idp-app/-/blob/main/packages/app/src/App.tsx#L63-108
* Adjust `packages/app/src/App.tsx` (also added in the use of GitHub on the login page here - guest may not work right with auth set up this way)

This became a bit more fletchy between other Backstage instances but hopefully the commit contains it decently. A way to map the logged in user from GitHub to a user entity in Backstage would still be needed to be fully proper.