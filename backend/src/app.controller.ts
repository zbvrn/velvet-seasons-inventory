import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import type { AppInfo } from './app-info.interface';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('info')
  getAppInfo(): AppInfo {
    return this.appService.getAppInfo();
  }
}
