import {
  CognitoIdentityProviderClient,
  InitiateAuthCommand,
  AuthFlowType,
} from '@aws-sdk/client-cognito-identity-provider';
import { Injectable } from '@nestjs/common';
import { CognitoJwtVerifier } from 'aws-jwt-verify';
import { createHmac } from 'crypto';
import { AuthResponseDto } from 'src/auth/dto/auth-response.dto';
import { LoginDto } from 'src/auth/dto/login.dto';

@Injectable()
export class AuthService {
  private readonly cognitoClient: CognitoIdentityProviderClient;

  constructor() {
    this.cognitoClient = new CognitoIdentityProviderClient({
      region: process.env.AWS_REGION,
    });
  }

  private verifier = CognitoJwtVerifier.create({
    userPoolId: this.getUserPoolId(),
    tokenUse: 'access',
    clientId: this.getClientId(),
  });

  private getUserPoolId(): string {
    const userPoolId = process.env.COGNITO_USER_POOL_ID;
    if (!userPoolId) {
      throw new Error('Varaible not found');
    }
    return userPoolId;
  }

  private getClientId(): string {
    const userPoolId = process.env.COGNITO_CLIENT_ID;
    if (!userPoolId) {
      throw new Error('Varaible not found');
    }
    return userPoolId;
  }

  private calculateSecretHash(username: string): string {
    const clientSecret = process.env.COGNITO_CLIENT_SECRET;
    if (!clientSecret) {
      throw new Error('COGNITO_CLIENT_SECRET no está configurado');
    }

    return createHmac('sha256', clientSecret)
      .update(username + process.env.COGNITO_CLIENT_ID)
      .digest('base64');
  }

  async validateToken(token: string) {
    try {
      const payload = await this.verifier.verify(token);
      return payload;
    } catch (err) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
      throw new Error('Invalid token', err);
    }
  }

  async login(loginDto: LoginDto): Promise<AuthResponseDto> {
    const params = {
      AuthFlow: AuthFlowType.USER_PASSWORD_AUTH,
      ClientId: this.getClientId(),
      AuthParameters: {
        USERNAME: loginDto.username,
        PASSWORD: loginDto.password,
        SECRET_HASH: this.calculateSecretHash(loginDto.username),
      },
    };

    try {
      const command = new InitiateAuthCommand(params);
      const response = await this.cognitoClient.send(command);

      if (response.ChallengeName === 'NEW_PASSWORD_REQUIRED') {
        throw new Error('NEW_PASSWORD_REQUIRED: The user must change their temporary password');
      }

      if (!response.AuthenticationResult) {
        throw new Error('Cognito did not develop authentication tokens');
      }
      return {
        accessToken: response.AuthenticationResult?.AccessToken || '',
        idToken: response.AuthenticationResult?.IdToken || '',
        refreshToken: response.AuthenticationResult?.RefreshToken,
      };
    } catch (error: unknown) {
      if (error instanceof Error) {
        throw new Error(`Login failed: ${error.message}`);
      }
      throw new Error('Login failed: Unknown error');
    }
  }
}
