import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import request from 'supertest';
import type { App } from 'supertest/types';
import { TechnicalCondition } from '../src/technical-conditions/technical-condition.entity';
import { TechnicalConditionsModule } from '../src/technical-conditions/technical-conditions.module';

describe('TechnicalConditions HTTP', () => {
  let app: INestApplication<App>;

  const repository = {
    find: jest.fn<Promise<TechnicalCondition[]>, []>(),
  };

  beforeEach(async () => {
    repository.find.mockReset();

    const moduleFixture = await Test.createTestingModule({
      imports: [TechnicalConditionsModule],
    })
      .overrideProvider(getRepositoryToken(TechnicalCondition))
      .useValue(repository)
      .compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterEach(async () => {
    if (app) {
      await app.close();
    }
  });

  it('GET /technical-conditions возвращает записи справочника', async () => {
    repository.find.mockResolvedValue([
      {
        id: '2',
        code: 'working',
        name: 'Исправно',
        isActive: 1,
      },
    ]);

    await request(app.getHttpServer())
      .get('/technical-conditions')
      .expect(200)
      .expect('Content-Type', /json/)
      .expect([
        {
          id: '2',
          code: 'working',
          name: 'Исправно',
          isActive: 1,
        },
      ]);
  });

  it('GET /technical-conditions возвращает [] для пустого справочника', async () => {
    repository.find.mockResolvedValue([]);

    await request(app.getHttpServer())
      .get('/technical-conditions')
      .expect(200)
      .expect([]);
  });
});
