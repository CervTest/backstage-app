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

### GitLab

Find the Gitlab plugin at this link:

  * https://github.com/immobiliare/backstage-plugin-gitlab - front and back end

Full instructions are at the link, but are written assuming the reader has some level of expertise in Backstage plugin installation and/or Node development, so specific instructions follow.

If you desire more information beyond the installation basics, then see the link to the plugin.

#### GitLab Plugin Installation

*BIG NOTE:* The GitLab plugin comes with an annotation to enable for a given entity like many other plugins do. However if that entity does not _live_ in a GitLab repo and is ingested by Backstage from its native habitat it may fail to list GitLab details. A different entity imported directly from GitLab should work fine.

Example: https://gitlab.adaptavist.net/backstage/clients/draper/deployments/jira2/-/blob/master/catalog-info.yml

##### Install Plugin

In the Backstage root directory, run:

```
yarn --cwd packages/app add @immobiliarelabs/backstage-plugin-gitlab
yarn --cwd packages/backend add @immobiliarelabs/backstage-plugin-gitlab-backend
```

##### Editing Config Files

The configuration files can be arranged differently based on user preference and/or use case. This largely affects positioning on the screen when the page is rendered in the browser. Therefore, this section will simply refer you to the edited configuration files, and within them, locate the lines that have been bracketed with the comment "Gitlab plugin".

The following configuration files were edited or created:

  * packages/app/src/components/catalog/EntityPage.tsx
    * Note that I added the plugin section to both the overview and website sections.
  * app-config.yaml
    * Just for the Gitlab integration, which may already be there.
  * packages/backend/src/plugins/catalog.ts
  * packages/backend/src/plugins/gitlab.ts
  * packages/backend/src/index.ts

##### The New Backend System

Not currently in use.


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


## Confluence Plugin

This is 2 separate plugins, one for app and the other for backend.

References are made to the files in this repository for adding code, instead of documentation, as the documentation may be out of date for newer versions of Backstage, and tend to assume a level of expertise with Node and how the backend operates.

### app

https://github.com/K-Phoen/backstage-plugin-confluence/tree/main/plugins/search-confluence

Add plugin to the front end:

`cd packages/app && yarn add @k-phoen/backstage-plugin-confluence`

See the file packages/app/src/components/search/SearchPage.tsx and search for code inserted between `conf plugin start/end` comments to see where code was added.

### backend

https://github.com/K-Phoen/backstage-plugin-confluence/tree/main/plugins/search-confluence-backend

Add plugin to the backend:

`cd packages/backend && yarn add @k-phoen/backstage-plugin-confluence-backend`

See the files app-config.yaml and packages/backend/src/plugins/search.ts and search for code inserted between `conf plugin start/end` comments to see where code was added.

For API testing you can use:

* Cloud: `curl -u <email>:<unencoded PAT> https://venuesh.atlassian.net/wiki/rest/api/content/`
* DC: `curl -H "Authorization: Bearer <unencoded PAT>" https://i.adaptavist.com/rest/api/space/DH`

However, unlike the Jira plugin's use of proxy config Confluence defines an integration which may not include the freedom to supply custom headers to vary between Cloud and DC :-(