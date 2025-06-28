import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import * as dotenv from 'dotenv';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { CognitoGuard } from 'src/auth/cognito.guard';

dotenv.config();

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.enableCors({
    origin: [
      'http://localhost:3000', // Frontend en desarrollo
      'http://localhost:3001', // Frontend en puerto alternativo
      'http://localhost:5173', // Vite dev server
      'http://localhost:8080', // Otros puertos comunes
      'https://loyalty-app.net', // Tu dominio futuro
      'https://app.loyalty-app.net', // Subdominio futuro
      'https://api.loyalty-app.net', // API subdominio futuro
    ],
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    credentials: true,
  });

  const config = new DocumentBuilder()
    .setTitle('Loyalty App API')
    .setDescription('API para el sistema de fidelización')
    .setVersion('1.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Ingresa tu token de Cognito',
      },
      'cognito', // Este nombre debe coincidir con el usado en @ApiBearerAuth()
    )
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api-docs', app, document);

  await app.listen(process.env.PORT ?? 3000);
  app.useGlobalGuards(new CognitoGuard());
}
void bootstrap();
