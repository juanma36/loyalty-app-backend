import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { CognitoJwtVerifier } from 'aws-jwt-verify';
import {
  CognitoIdentityProviderClient,
  InitiateAuthCommand,
} from '@aws-sdk/client-cognito-identity-provider';
import { Request, Response } from 'express';
import { createHmac } from 'crypto';
import * as dotenv from 'dotenv';

dotenv.config();

@Injectable()
export class CognitoGuard implements CanActivate {
  private cognitoClient: CognitoIdentityProviderClient;

  constructor() {
    this.cognitoClient = new CognitoIdentityProviderClient({
      region: process.env.AWS_REGION,
    });
  }

  private verifier = CognitoJwtVerifier.create({
    userPoolId:
      process.env.COGNITO_USER_POOL_ID ||
      (() => {
        throw new Error('COGNITO_USER_POOL_ID is not defined');
      })(),
    tokenUse: 'access', // o 'id' según tu caso
    clientId: process.env.COGNITO_CLIENT_ID || '',
  });

  private cognitoIdentityServiceProvider = new CognitoIdentityProviderClient({
    region: process.env.AWS_REGION,
  });
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const token = this.extractToken(request);

    if (!token) {
      throw new UnauthorizedException('Token not provided');
    }

    try {
      const payload = await this.verifier.verify(token, {
        tokenUse: 'access',
        clientId: process.env.COGNITO_CLIENT_ID,
      });
      request['user'] = payload; // Adjunta el payload a la request
      return true;
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      throw new UnauthorizedException('Token inválido: ' + errorMessage);
    }
  }

  private async handleExpiredToken(request: Request, response: Response): Promise<boolean> {
    const refreshToken = this.extractRefreshToken(request);

    if (!refreshToken) {
      throw new UnauthorizedException('Access token expired and no refresh token provided');
    }

    try {
      const newTokens = await this.refreshAccessToken(refreshToken, request);

      response.setHeader('New-Access-Token', newTokens.AccessToken ?? '');
      response.setHeader('New-Id-Token', newTokens.IdToken ?? '');

      // Verificar el nuevo token y adjuntarlo a la request
      const payload = await this.verifier.verify(newTokens.IdToken ?? '', {
        tokenUse: 'access',
        clientId: process.env.COGNITO_CLIENT_ID,
      });
      request['user'] = payload;

      return true;
    } catch (refreshError: unknown) {
      const errorMessage = refreshError instanceof Error ? refreshError.message : 'Unknown error';
      throw new UnauthorizedException('Failed to refresh token: ' + errorMessage);
    }
  }

  private extractRefreshToken(request: Request): string | null {
    const refreshToken = request.headers['x-refresh-token'];
    return typeof refreshToken === 'string' ? refreshToken : null;
  }

  private async refreshAccessToken(refreshToken: string, request: Request) {
    const command = new InitiateAuthCommand({
      AuthFlow: 'REFRESH_TOKEN_AUTH',
      ClientId: process.env.COGNITO_CLIENT_ID,
      AuthParameters: {
        REFRESH_TOKEN: refreshToken,
        ...(process.env.COGNITO_CLIENT_SECRET && {
          SECRET_HASH: this.calculateSecretHash(
            process.env.COGNITO_CLIENT_ID ?? '',
            process.env.COGNITO_CLIENT_SECRET,
            this.getUsernameFromExpiredToken(request) || 'unknown',
          ),
        }),
      },
    });

    try {
      const response = await this.cognitoClient.send(command);

      if (!response.AuthenticationResult) {
        throw new Error('Authentication failed - no tokens returned');
      }

      return {
        AccessToken: response.AuthenticationResult.AccessToken,
        IdToken: response.AuthenticationResult.IdToken,
        TokenType: response.AuthenticationResult.TokenType,
        ExpiresIn: response.AuthenticationResult.ExpiresIn,
      };
    } catch (error) {
      console.error('Error refreshing token:', error);
      throw new Error('Failed to refresh token');
    }
  }

  private getUsernameFromExpiredToken(request: Request): string | null {
    // 1. Intenta obtener el token expirado del header Authorization
    const expiredToken = this.extractToken(request);

    if (!expiredToken) return null;

    try {
      // 2. Decodifica el token sin verificar (ya que está expirado)
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      const payload = this.decodeJwtPayload(expiredToken);

      // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-member-access
      return payload['username'] || payload['cognito:username'] || null;
    } catch (error) {
      console.warn('Failed to decode expired token:', error);
      return null;
    }
  }

  private decodeJwtPayload(token: string): any {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join(''),
    );
    return JSON.parse(jsonPayload);
  }

  private extractToken(request: Request): string | undefined {
    const [type, token] = request.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }

  private calculateSecretHash(clientId: string, clientSecret: string, username: string): string {
    return createHmac('SHA256', clientSecret)
      .update(username + clientId)
      .digest('base64');
  }
}
