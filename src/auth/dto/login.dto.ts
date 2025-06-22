import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({ example: 'usuario@ejemplo.com' })
  username: string;

  @ApiProperty({ example: 'MiClaveSegura123!' })
  password: string;
}
