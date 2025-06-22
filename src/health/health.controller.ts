import { Controller, Get } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(private dataSource: DataSource) {}

  @ApiOperation({ summary: 'health check' })
  @ApiResponse({
    status: 200,
    description: 'service status',
  })
  @Get()
  async checkDatabase() {
    try {
      await this.dataSource.query('SELECT 1');
      return {
        status: 'OK',
        database: 'Connected successfully to DB',
        timestamp: new Date().toISOString(),
      };
    } catch (error: unknown) {
      return {
        status: 'Error',
        database: 'Connection failed',
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }
}
