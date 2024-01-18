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

### Sonar

This plugin supports either [Sonarqube](https://www.sonarsource.com/products/sonarqube/) (self-managed) and [SonarCloud](https://www.sonarsource.com/products/sonarcloud/)

It has both front-end and back-end plugins, commands need to run from the root directory of a Backstage workspace.

#### Front-end

https://github.com/backstage/backstage/blob/master/plugins/sonarqube/README.md

* `yarn add --cwd packages/app @backstage/plugin-sonarqube`
* Add a card to `EntityPage.tsx` as per instructions
* Add an annotation to relevant entities like so: `sonarqube.org/project-key: YOUR_PROJECT_KEY`
* Yarn install, tsc, and test with some entity (after back-end is also ready)

Note that this example adds the Code Quality card to _every_ entity regardless of whether the Sonarqube annotation is present or if the project exists. A better conditional approach is warranted but is at present outside the scope of this sample implementation.

#### Back-end

For simplicity still not using the new backend system instructions

https://github.com/backstage/backstage/blob/master/plugins/sonarqube-backend/README.md

* `yarn add --cwd packages/backend @backstage/plugin-sonarqube-backend`
* Add `packages/backend/src/plugins/sonarqube.ts` with text provided
* Adjust `packages/backend/src/index.ts` as per instructions
* Add a `sonarqube` block to config
  * Note that the API token needs a certain level of access, a user token from an admin user was enough. You can test a token while bypassing Backstage with: `curl -X GET -H "Authorization: Bearer <api token>" "https://<sonar host>/api/projects/search?projects=<project key>"`
