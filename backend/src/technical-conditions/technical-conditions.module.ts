import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TechnicalCondition } from './technical-condition.entity';
import { TechnicalConditionsController } from './technical-condition.controller';
import { TechnicalConditionsService } from './technical-condition.service';

@Module({
  imports: [TypeOrmModule.forFeature([TechnicalCondition])],
  controllers: [TechnicalConditionsController],
  providers: [TechnicalConditionsService],
})
export class TechnicalConditionsModule {}
