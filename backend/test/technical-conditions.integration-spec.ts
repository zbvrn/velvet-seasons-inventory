import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import type { TestingModule } from '@nestjs/testing';
import { DatabaseModule } from '../src/database/database.module';
import { TechnicalConditionsModule } from '../src/technical-conditions/technical-conditions.module';
import { TechnicalConditionsService } from '../src/technical-conditions/technical-condition.service';

describe('TechnicalConditions: интеграция с MariaDb', () => {
  let moduleFixture: TestingModule | undefined;
  let service: TechnicalConditionsService;

  beforeAll(async () => {
    const envFilePath = resolve(__dirname, '../.env.test');

    if (!existsSync(envFilePath)) {
      throw new Error('Создай backend/.env.test с настройками тестовой БД');
    }

    moduleFixture = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          envFilePath,
          validate: (config: Record<string, unknown>) => {
            if (config.DB_DATABASE !== 'velvet_inventory_test') {
              throw new Error(
                'Интеграционный тест требует DB_DATABASE=velvet_inventory_test',
              );
            }

            if (config.DB_HOST !== '127.0.0.1') {
              throw new Error(
                'Этот тест настроен на локальную MariaDB: DB_HOST=127.0.0.1',
              );
            }

            return config;
          },
        }),
        DatabaseModule,
        TechnicalConditionsModule,
      ],
    }).compile();

    await moduleFixture.init();

    service = moduleFixture.get(TechnicalConditionsService);
  }, 30000);

  afterAll(async () => {
    await moduleFixture?.close();
  });

  it('читает справочник с правильными полями и порядком', async () => {
    const result = await service.findAll();

    expect(result).toEqual([
      {
        id: '1',
        code: 'unknown',
        name: 'Неизвестно',
        isActive: 1,
      },
      {
        id: '2',
        code: 'working',
        name: 'Исправно',
        isActive: 1,
      },
      {
        id: '3',
        code: 'faulty',
        name: 'Неисправно',
        isActive: 1,
      },
    ]);
  });
});
