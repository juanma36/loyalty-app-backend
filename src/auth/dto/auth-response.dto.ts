import { ApiProperty } from '@nestjs/swagger';

export class AuthResponseDto {
  @ApiProperty({ description: 'JWT Access Token' })
  accessToken: string;

  @ApiProperty({ description: 'JWT ID Token' })
  idToken: string;

  @ApiProperty({ description: 'Token de refresco' })
  refreshToken?: string;
}
