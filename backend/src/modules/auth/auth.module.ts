import { Module } from '@nestjs/common';
import { AuthController } from './presentation/auth.controller';
import { SignInUseCase } from './domain/sign-in.use-case';
import { CompleteSignupUseCase } from './domain/complete-signup.use-case';
import { PrismaAuthRepository } from './data/prisma-auth.repository';
import { FirebaseVerifierAdapter } from './data/adapters/firebase-verifier.adapter';
import { AUTH_REPOSITORY } from './domain/auth.repository';

@Module({
  controllers: [AuthController],
  providers: [
    SignInUseCase,
    CompleteSignupUseCase,
    FirebaseVerifierAdapter,
    PrismaAuthRepository,
    { provide: AUTH_REPOSITORY, useClass: PrismaAuthRepository },
  ],
})
export class AuthModule {}
