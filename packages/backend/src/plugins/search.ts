import { useHotCleanup } from '@backstage/backend-common';
import { createRouter } from '@backstage/plugin-search-backend';
import {
  IndexBuilder,
  LunrSearchEngine,
} from '@backstage/plugin-search-backend-node';
import { PluginEnvironment } from '../types';
import { DefaultCatalogCollatorFactory } from '@backstage/plugin-search-backend-module-catalog';
import { DefaultTechDocsCollatorFactory } from '@backstage/plugin-search-backend-module-techdocs';
import { Router } from 'express';
// conf plugin start
import { ConfluenceCollatorFactory } from '@k-phoen/backstage-plugin-confluence-backend';
// conf plugin end

export default async function createPlugin(
  env: PluginEnvironment,
): Promise<Router> {
  // Initialize a connection to a search engine.
  const searchEngine = new LunrSearchEngine({
    logger: env.logger,
  });
  const indexBuilder = new IndexBuilder({
    logger: env.logger,
    searchEngine,
  });

  const schedule = env.scheduler.createScheduledTaskRunner({
    frequency: { minutes: 10 },
    timeout: { minutes: 15 },
    // A 3 second delay gives the backend server a chance to initialize before
    // any collators are executed, which may attempt requests against the API.
    initialDelay: { seconds: 3 },
  });

  // Collators are responsible for gathering documents known to plugins. This
  // collator gathers entities from the software catalog.
  indexBuilder.addCollator({
    schedule,
    factory: DefaultCatalogCollatorFactory.fromConfig(env.config, {
      discovery: env.discovery,
      tokenManager: env.tokenManager,
    }),
  });

  // collator gathers entities from techdocs.
  indexBuilder.addCollator({
    schedule,
    factory: DefaultTechDocsCollatorFactory.fromConfig(env.config, {
      discovery: env.discovery,
      logger: env.logger,
      tokenManager: env.tokenManager,
    }),
  });

  // conf plugin start
  // const halfHourSchedule = env.scheduler.createScheduledTaskRunner({
  //   frequency: Duration.fromObject({ minutes: 30 }),
  //   timeout: Duration.fromObject({ minutes: 15 }),
  //   // A 3 second delay gives the backend server a chance to initialize before
  //   // any collators are executed, which may attempt requests against the API.
  //   initialDelay: Duration.fromObject({ seconds: 3 }),
  // });
  indexBuilder.addCollator({
    schedule: schedule,
    factory: ConfluenceCollatorFactory.fromConfig(env.config, {
      logger: env.logger,
    }),
  });
  // conf plugin end

  // The scheduler controls when documents are gathered from collators and sent
  // to the search engine for indexing.
  const { scheduler } = await indexBuilder.build();
  scheduler.start();

  useHotCleanup(module, () => scheduler.stop());

  return await createRouter({
    engine: indexBuilder.getSearchEngine(),
    types: indexBuilder.getDocumentTypes(),
    permissions: env.permissions,
    config: env.config,
    logger: env.logger,
  });
}
