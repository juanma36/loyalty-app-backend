import { User } from '../src/auth/user.entity';
import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import { Customer } from '../src/customer/customer.entity';

dotenv.config();

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST,
  port: process.env.DB_PORT ? parseInt(process.env.DB_PORT) : 5432,
  username: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_DATABASE,
  entities: [User, Customer],
  migrations: ['src/migrations/*.ts'],
  synchronize: false,
  logging: true,
});
