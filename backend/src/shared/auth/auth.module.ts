import { Global, Module } from '@nestjs/common';
import { JwtService } from './jwt.service';
import { AuthGuard } from './auth.guard';

@Global()
@Module({
  providers: [JwtService, AuthGuard],
  exports: [JwtService, AuthGuard],
})
export class SharedAuthModule {}
