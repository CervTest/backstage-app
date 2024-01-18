import { CatalogBuilder } from '@backstage/plugin-catalog-backend';
import { ScaffolderEntitiesProcessor } from '@backstage/plugin-catalog-backend-module-scaffolder-entity-model';
import { Router } from 'express';
import { PluginEnvironment } from '../types';
//gitlab plugin
import { GitlabFillerProcessor } from '@immobiliarelabs/backstage-plugin-gitlab-backend';
// gitlab plugin

export default async function createPlugin(
  env: PluginEnvironment,
): Promise<Router> {
  const builder = await CatalogBuilder.create(env);
  // gitlab plugin
  builder.addProcessor(new GitlabFillerProcessor(env.config));
  // gitlab plugin
  builder.addProcessor(new ScaffolderEntitiesProcessor());
  const { processingEngine, router } = await builder.build();
  await processingEngine.start();
  return router;
}
