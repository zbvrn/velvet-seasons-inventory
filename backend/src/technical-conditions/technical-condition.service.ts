import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import type { Repository } from 'typeorm';
import { TechnicalCondition } from './technical-condition.entity';

@Injectable()
export class TechnicalConditionsService {
  constructor(
    @InjectRepository(TechnicalCondition)
    private readonly repository: Repository<TechnicalCondition>,
  ) {}

  findAll(): Promise<TechnicalCondition[]> {
    return this.repository.find({
      order: {
        id: 'ASC',
      },
    });
  }
}
