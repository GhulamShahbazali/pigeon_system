import { DomainError } from '../errors/domain-error';

export type Result<T> = { ok: true; value: T } | { ok: false; error: DomainError };

export const Ok = <T>(value: T): Result<T> => ({ ok: true, value });
export const Err = (error: DomainError): Result<never> => ({ ok: false, error });
