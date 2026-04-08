import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import * as express from 'express';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable CORS
  app.enableCors();

  // Integrated global validation pipe
  app.useGlobalPipes(new ValidationPipe());

  // Set global prefix
  app.setGlobalPrefix('api');

  // Serve static files (uploads)
  app.use('/uploads', express.static(join(process.cwd(), 'uploads')));

  const PORT = process.env.PORT || 3000;
  await app.listen(PORT, '0.0.0.0');
  console.log(`Application is running on: http://localhost:${PORT}/api`);
}
bootstrap();
