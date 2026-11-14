import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import type { TypeOrmModuleOptions } from '@nestjs/typeorm';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService): TypeOrmModuleOptions => {
        const port = Number(config.getOrThrow<string>('DB_PORT'));

        if (!Number.isInteger(port) || port < 1 || port > 65535) {
          throw new Error('DB_PORT должен быть целым числом от 1 до 65535');
        }

        return {
          type: 'mariadb',
          host: config.getOrThrow<string>('DB_HOST'),
          port,
          username: config.getOrThrow<string>('DB_USERNAME'),
          password: config.getOrThrow<string>('DB_PASSWORD'),
          database: config.getOrThrow<string>('DB_DATABASE'),

          autoLoadEntities: true,
          synchronize: false,
          migrationsRun: false,

          timezone: 'Z',
          supportBigNumbers: true,
          bigNumberStrings: true,
          retryAttempts: 1,
        };
      },
    }),
  ],
})
export class DatabaseModule {}
