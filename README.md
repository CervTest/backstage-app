# [Backstage](https://backstage.io)

This is your newly scaffolded Backstage App, Good Luck!

To start the app, run:

```sh
yarn setup
yarn install
yarn dev
```

## A few technical details

* The `yarn setup` step has been added for a bit of developer utility, including shipped templates for `.env` and the `app-config.local.yaml` file Backstage looks for automatically on local-only execution
* The `packages/backend/Dockerfile` remains unmodified as of this writing and works - optimization in a multi-layered build can come later. It starts in `/app` meaning links to local catalog files need to look there, not in `../..` as is done when running from source
  * Instructions for building Docker are available within the Dockerfile
* The included `Jenkinsfile` can successfully build and publish the Docker image when paired with a compatible Jenkins setup (targets Google Container Registry, easy to change)
* There is a separate infra repo at https://github.com/CervTest/backstage-infra with another Jenkinsfile that knows how to deploy to a public demo Backstage via Helm
  * This further supports secrets imported via Jenkins credentials and a `cm-app-config.extra.yaml` that is supplied in a Kubernetes context and wired up for the Backstage container without further config or rebuild needed 

## Plugins

For Backstage plugins have traditionally been applied directly to source code, while also relying on a Node dependency. As such it has been tricky to "install" a bunch of plugins quickly, as each takes modifying source files, often overlapping. One approach to at least _seeing_ how individual plugins work is making a new branch off `basic` then solely installing a single plugin there. Later instance branches (like `main`) that correspond to a given Backstage can be merged into from various plugin branches with any conflicts resolved then.

While working locally with this approach it is important to keep your config files and .gitignored files in mind, lest you end up with a plugin and a half if for instance `app-config.local.yaml` has not been deleted. The `.env` file will also not overwrite when running `yarn setup` again, but then generally won't cause trouble from having more new variables added than needed.

### Jenkins (new)

Unlike the older version of the Jenkins plugin the new approach targeting new architecture is split into two:

* https://github.com/backstage/backstage/tree/master/plugins/jenkins - front-end plugin
* https://github.com/backstage/backstage/tree/master/plugins/jenkins-backend - back-end, naturally

Full instructions via links, abbreviated instructions follow

Note that this example only applies the Jenkins extras to entities of type _service_ - you wouldn't see anything different on a type _website_ for instance. It is left as an exercise to the reader where to enable what.

#### Front-end

* `yarn add --cwd packages/app @backstage/plugin-jenkins` (from the root dir, unlike app dir with old plugin)
* Adjust `EntityPage.tsx` as instructed - although some personal preference on where to place and what to keep might be involved here (like the `{overviewContent}` type blocks might need to get moved around a bit and/or copied, conditional blocks may be warranted)
  * Note additionally that the entity card meant for the overview is branch-targeted - adjust naming to your conventions (the `EntityLatestJenkinsRunCard`)
* Add the Jenkins annotation to a given catalog item, for instance `jenkins.io/job-full-name: Experimental/CervTest/jibby`
* Optionally tweak at the columns included as noted in the docs

#### Back-end

* The instructions mentions support for the new backend system, but that may take extra config elsewhere first so probably best to skip, for now
* `yarn add --cwd packages/backend @backstage/plugin-jenkins-backend` (again from the root dir)
* Create the `jenkins.ts` file under `packages/backend/src/plugins`
* Adjust `packages/backend/src/index.ts` slightly
* Add a Jenkins section in config (get API key from a Jenkins user account then base64 encode it)
* Add an annotation on a catalog item to pair with a job path in Jenkins
* Multiple instances or custom JenkinsInfoProvider is out of scope for this test setup (not needed)

#### Jenkins API access

This turned out to be the trickiest part. A user token is needed to access the API, which can be generated on the user's profile page in Jenkins under "configure" - however, exact configuration details may be finicky about whether or not that user has the right permissions to use the API, even if they're fine working in the web UI.

Additionally the API key should _not_ be base64 encoded despite older instructions.

Can test with something like the following: 

`curl -u cervator:<api key> https://jenkins.terasology.io/job/CervTest/api/json`

A bad setup will result in 401 errors, while a valid user with incorrect permissions may hit 403 errors instead, with `cervator is missing the Overall/Read permission` buried somewhere in the returned HTML.

Turns out that despite a user actually being "Cervator" on GitHub with Jenkins configured with the GitHub Auth plugin, and being able to be granted admin rights in the web UI just fine as "Cervator" if using the API apparently the user _must_ be granted permissions in all lowercase, and likewise used in lower case on the API calls. Who knew?
 