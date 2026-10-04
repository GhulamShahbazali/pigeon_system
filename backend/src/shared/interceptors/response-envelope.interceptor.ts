import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

/** Wraps success responses as { data, meta? }. A handler may return { data, meta } to pass meta. */
@Injectable()
export class ResponseEnvelopeInterceptor implements NestInterceptor {
  intercept(_ctx: ExecutionContext, next: CallHandler): Observable<unknown> {
    return next.handle().pipe(
      map((payload) => {
        if (payload === undefined || payload === null) return { data: null };
        if (typeof payload === 'object' && payload !== null && 'data' in (payload as object)) {
          return payload; // already enveloped (carries meta)
        }
        return { data: payload };
      }),
    );
  }
}
