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

### GitHub

This is actually a whole series of little plugins doing different things with GitHub

Some base GitHub things are available out of the box and are needed for some of the plugins, largely the GitHub integration (to create/modify repos) and the auth provider (be it for the base login or enriching with additional detail). The two main blocks to have active in config thus are:

```
integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN}
auth:
  environment: development
  providers:
    github:
      development:
        clientId: ${GITHUB_AUTH_CLIENT_ID}
        clientSecret: ${GITHUB_AUTH_CLIENT_SECRET}
```

Additionally the catalog files for entities will likely need one or more GitHub annotations. The main one is `github.com/project-slug: 'backstage/backstage'` (adjusting path accordingly)

#### Codespaces

Adds management and visibility to an entity page for associated Codespaces for the repo on GitHub. See https://github.com/adityasinghal26/backstage-plugins/tree/main/plugins/github-codespaces

* `yarn add --cwd packages/app @adityasinghal26/plugin-github-codespaces`
* Add snippets to `EntityPage.tsx` as per instructions and desire
* If needed due to Codespace config add the annotation to target: `github.com/devcontainer-path: .devcontainer/devcontainer.json` (leaving it out is fine, typically default setup should work)
* Adjust `App.tsx` and `Root.tsx` as per instructions if the sidebar entry is wanted
  * Note that the `GithubCodespacesPage` import is _not_ needed in `Root.tsx` only `App.tsx`

#### Pull Requests

To show PRs per component. See https://roadie.io/backstage/plugins/github-pull-requests

* From `packages/app`: `yarn add @roadiehq/backstage-plugin-github-pull-requests`
* Adjust `EntityPage.tsx` for one or more component types as per instructions, along with the overview card


### Keycloak

For using Keycloak for authentication and the like - https://access.redhat.com/documentation/en-us/red_hat_plug-ins_for_backstage/1.0/html-single/keycloak_backend_plugin_for_backstage - or maybe https://github.com/janus-idp/backstage-plugins/tree/main/plugins/keycloak-backend could be easier and more complete

* `yarn workspace backend add @janus-idp/backstage-plugin-keycloak-backend`
* Create a client in Keycloak (don't forget not to use the "master" realm)
  * Must enable "Service accounts roles" along with "Client authentication"
  * For "Access settings" user the base URL for Root, Home, and Web origins, then the same plus `/*` for redirects
  * Then add some roles from the _existing_ client named "realm-management" via the "Service accounts roles" tab on the new Backstage client (clikc the "Assign Roles" button then filter)
    * `query-groups`
    * `query-users`
    * `view-users`
  * However, those may not match a newer version of Keycloak, tried `query-groups` and `manage-users`
* Fill in env vars for Backstage to use with Keycloak
* Add to `catalog.ts` to activate the plugin:

```
import { KeycloakOrgEntityProvider } from '@janus-idp/backstage-plugin-keycloak-backend';
...
  builder.addEntityProvider(
    KeycloakOrgEntityProvider.fromConfig(env.config, {
      id: 'development',
      logger: env.logger,
      scheduler: env.scheduler,
    }),
  );
```