import { Controller, Get } from '@nestjs/common';
import { TechnicalConditionsService } from './technical-condition.service';
import type { TechnicalCondition } from './technical-condition.entity';

@Controller('technical-conditions')
export class TechnicalConditionsController {
  constructor(
    private readonly technicalConditionsService: TechnicalConditionsService,
  ) {}

  @Get()
  findAll(): Promise<TechnicalCondition[]> {
    return this.technicalConditionsService.findAll();
  }
}
