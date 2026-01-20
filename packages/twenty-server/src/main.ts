import { NestFactory } from '@nestjs/core';
import { type NestExpressApplication } from '@nestjs/platform-express';

import fs from 'fs';

import bytes from 'bytes';
import { useContainer } from 'class-validator';
import session from 'express-session';
import graphqlUploadExpress from 'graphql-upload/graphqlUploadExpress.mjs';

import { NodeEnvironment } from 'src/engine/core-modules/twenty-config/interfaces/node-environment.interface';

import { setPgDateTypeParser } from 'src/database/pg/set-pg-date-type-parser';
import { LoggerService } from 'src/engine/core-modules/logger/logger.service';
import { getSessionStorageOptions } from 'src/engine/core-modules/session-storage/session-storage.module-factory';
import { TwentyConfigService } from 'src/engine/core-modules/twenty-config/twenty-config.service';
import { UnhandledExceptionFilter } from 'src/filters/unhandled-exception.filter';

import { AppModule } from './app.module';
import './instrument';

import { settings } from './engine/constants/settings';
import { generateFrontConfig } from './utils/generate-front-config';

const bootstrap = async () => {
  setPgDateTypeParser();

  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    cors: true,
    bufferLogs: process.env.LOGGER_IS_BUFFER_ENABLED === 'true',
    rawBody: true,
    snapshot: process.env.NODE_ENV === NodeEnvironment.DEVELOPMENT,
    ...(process.env.SSL_KEY_PATH && process.env.SSL_CERT_PATH
      ? {
          httpsOptions: {
            key: fs.readFileSync(process.env.SSL_KEY_PATH),
            cert: fs.readFileSync(process.env.SSL_CERT_PATH),
          },
        }
      : {}),
  });
  const logger = app.get(LoggerService);
  const twentyConfigService = app.get(TwentyConfigService);

  app.use(session(getSessionStorageOptions(twentyConfigService)));

  // Apply class-validator container so that we can use injection in validators
  useContainer(app.select(AppModule), { fallbackOnErrors: true });

  // Use our logger
  app.useLogger(logger);

  app.useGlobalFilters(new UnhandledExceptionFilter());

  app.useBodyParser('json', { limit: settings.storage.maxFileSize });
  app.useBodyParser('urlencoded', {
    limit: settings.storage.maxFileSize,
    extended: true,
  });

  // Graphql file upload
  app.use(
    '/graphql',
    graphqlUploadExpress({
      maxFieldSize: bytes(settings.storage.maxFileSize),
      maxFiles: 10,
    }),
  );

  app.use(
    '/metadata',
    graphqlUploadExpress({
      maxFieldSize: bytes(settings.storage.maxFileSize),
      maxFiles: 10,
    }),
  );

  // Inject the server url in the frontend page
  generateFrontConfig();

  const port = twentyConfigService.get('NODE_PORT');

  // Dual logging: both logger and console for visibility
  logger.log(`📡 Starting server on port ${port}...`, 'Bootstrap');
  console.log(`[Bootstrap] 📡 Starting server on port ${port}...`);
  console.log(`[Bootstrap] PORT from env: ${process.env.PORT || 'not set'}`);
  console.log(`[Bootstrap] NODE_PORT from env: ${process.env.NODE_PORT || 'not set'}`);
  console.log(`[Bootstrap] NODE_PORT from config service: ${port}`);

  try {
    const server = await app.listen(port, '0.0.0.0');

    // Dual logging: both logger and console for visibility
    logger.log(`🚀 Server is listening on port ${port}`, 'Bootstrap');
    logger.log(`🏥 Health check available at /healthz`, 'Bootstrap');
    console.log(`[Bootstrap] 🚀 Server is listening on port ${port}`);
    console.log(`[Bootstrap] 🏥 Health check available at /healthz`);
    console.log(`[Bootstrap] Server address: ${JSON.stringify(server.address())}`);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    const errorStack = error instanceof Error ? error.stack : undefined;
    logger.error(`❌ Failed to start server on port ${port}: ${errorMessage}`, errorStack, 'Bootstrap');
    console.error(`[Bootstrap] ❌ Failed to start server on port ${port}:`, error);
    console.error(`[Bootstrap] Error details:`, errorMessage);
    if (errorStack) {
      console.error(`[Bootstrap] Stack trace:`, errorStack);
    }
    throw error;
  }
};

bootstrap().catch((error) => {
  console.error('❌ Failed to start server:', error);
  console.error('❌ Error stack:', error instanceof Error ? error.stack : 'No stack trace');
  process.exit(1);
});
