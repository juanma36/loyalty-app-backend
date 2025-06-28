import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddEmailToCustomer1749390818598 implements MigrationInterface {
  name = 'AddEmailToCustomer1749390818598';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "customer" ADD "email" character varying NOT NULL`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "customer" DROP COLUMN "email"`);
  }
}
