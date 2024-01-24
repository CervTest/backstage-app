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

### Jira

Installing via instructions from https://github.com/RoadieHQ/roadie-backstage-plugins/tree/main/plugins/frontend/backstage-plugin-jira

* Run `yarn add @roadiehq/backstage-plugin-jira` from the `packages/app` directory
* Fashion a working auth request which can vary between Jira Cloud and DC. You need to start with a PAT from whichever user account will be involved in auth
  * IF CLOUD: Base64 encode `<email>:<PAT>` then wrap it like so: `'Basic <encoded token>'`
  * IF DC: Do _not_ Base64 encode and solely use your PAT with a Bearer format instead: `Bearer <PAT>"`
  * You can validate your API access using `curl` with something like the following, replacing `<AUTH>` with what you just prepared: `curl -X GET -H "Authorization: <AUTH>" -H "Content-Type: application/json" "https://venuesh.atlassian.net/rest/api/2/search?jql=project=VSH"` (or `https://tracker.adaptavist.com/rest/api/2/search?jql=project=DRAP` for a DC test)
* Adjust config with proxy details for Jira (store `JIRA_TOKEN=<encoded token>|<PAT>` depending on Cloud or DC)
  * IF CLOUD: `"Basic ${JIRA_TOKEN}"`
  * IF DC: `"Bearer ${JIRA_TOKEN}"`
  * The `jira` config block can be skipped if default proxy details are good enough
* Add your JIRA url as a CSP entry as per instructions
* Add a widget into `EntityPage.tsx`
* Add an annotation to a test entity like: `jira/project-key: VSH` 
* `yarn install`
* `yarn tsc`
* `yarn dev`
* Look at the test entity
