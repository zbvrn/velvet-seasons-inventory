import { Injectable } from '@nestjs/common';
import type { AppInfo } from './app-info.interface';

@Injectable()
export class AppService {
  getAppInfo(): AppInfo {
    return {
      application: 'Учет оборудования',
      status: 'ok',
    };
  }
}
