import { DomainError } from '../../../shared/errors/domain-error';

export class PigeonCapExceededError extends DomainError {
  readonly code = 'pigeon_cap_exceeded';
  readonly httpStatus = 422;
  constructor(cap: number) {
    super(`A participant may record at most ${cap} pigeons per day`);
    this.details = { fields: { pigeon: `max ${cap}` } };
  }
}

export class FlightBeforeReleaseError extends DomainError {
  readonly code = 'unprocessable';
  readonly httpStatus = 422;
  constructor() {
    super('Landing time is before the release time');
    this.details = { fields: { landing_time: 'must be after the fly time' } };
  }
}
