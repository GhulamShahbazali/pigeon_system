/** Base for all expected (business) failures. Carries the API error code + HTTP status. */
export abstract class DomainError extends Error {
  abstract readonly code: string;
  abstract readonly httpStatus: number;
  details?: Record<string, unknown>;

  constructor(message: string) {
    super(message);
    this.name = new.target.name;
  }
}
