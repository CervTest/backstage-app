import { Router } from 'express';
import { PluginEnvironment } from '../types';
import { createRouter } from '@spotify/backstage-plugin-skill-exchange-backend';

export default async function createPlugin(
  env: PluginEnvironment,
): Promise<Router> {
  return await createRouter({
    ...env,
  });
}