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

## Feature Flags

Flags can be very useful in Backstage, especially for a consultancy wanting to maintain multiple client instances without a ton of divergent code to maintain (possibly only in cases where we host the code, like with Venue or internally).

See https://backstage.io/docs/plugins/feature-flags/ for the main doc and https://backstage.io/docs/features/software-templates/writing-templates/#remove-sections-or-fields-based-on-feature-flags for using them to modify active sections in a template being processed by the Scaffolder.

Soundcheck being visible or not has been wired up that way in this instance, take a look at `App.tsx`, `EntityPage.tsx`, and `Root.tsx` - TODO probably link to a commit or more fully qualify the paths to go look there.

## Spotify Plugins

Instructions are public, but a license file is needed.

### Soundcheck

https://www.npmjs.com/package/@spotify/backstage-plugin-soundcheck-backend + https://www.npmjs.com/package/@spotify/backstage-plugin-soundcheck

* `yarn workspace backend add @spotify/backstage-plugin-soundcheck-backend` - backend
* `yarn workspace app add @spotify/backstage-plugin-soundcheck` - frontend
* Tweak / create some files as indicated by the instructions (already done)
  * Take a close look at `soundcheck-tracks.yaml` in the root of this repo for an initial set of certifications (also some related config in `app-config.yaml`)
* Optionally use the included demo content scripts (need to run where they can hit Backstage API)
  * `prep-soundcheck-demo.sh` - updates the results for some checks on three demo entities stored in `examples/bluedemo.yaml`
  * `fail-a-check.sh` - additionally marks one check as failed to see how that works. Can adjust these scripts as desired

Note that more work is needed to both go beyond demo material as well as truly making it work - checks are associated with the demo track but not actually defined beyond a single GitHub readme file check that uses a built-in action (which did not actually work during brief local testing)

Checks can be added as well although the specifics are still to be explored, particularly around mapping checks to tracks (may just be coincidental matches?) and actually having checks trigger and report results. For testing you can mark checks as passed via API like so from a terminal:

```
BACKSTAGE_BACKEND=localhost:7007 && \
curl \
  -H 'Content-Type: application/json' \
  "${BACKSTAGE_BACKEND}/api/soundcheck/results" \
  --data @- << EOF
{
  "results": [
    {
      "entityRef": "component:default/target-component-name",
      "checkId": "basic-head-bob",
      "state": "passed"
    }
  ]
}
EOF
```

Replace `target-component-name` with an entity to provided updated results for and `basic-head-bob` with any other desired check to pass. Use "failed" to fail a pass explicitly (default state until some update is unreported)
