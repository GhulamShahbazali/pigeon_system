import { PipeTransform } from '@nestjs/common';
import { ZodSchema, ZodError } from 'zod';
import { DomainError } from '../errors/domain-error';

class InvalidRequestError extends DomainError {
  readonly code = 'invalid_request';
  readonly httpStatus = 400;
  constructor(fields: Record<string, string>) {
    super('Invalid request');
    this.details = { fields };
  }
}

/** Validates a value against a Zod schema; maps ZodError → 400 invalid_request with per-field errors. */
export class ZodValidationPipe implements PipeTransform {
  constructor(private readonly schema: ZodSchema) {}

  transform(value: unknown): unknown {
    const result = this.schema.safeParse(value);
    if (result.success) return result.data;

    const fields: Record<string, string> = {};
    for (const issue of (result.error as ZodError).issues) {
      const path = issue.path.join('.') || '_root';
      if (!fields[path]) fields[path] = issue.message;
    }
    throw new InvalidRequestError(fields);
  }
}
