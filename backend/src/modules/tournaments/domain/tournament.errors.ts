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

export class FutureDayInactiveError extends DomainError {
  readonly code = 'future_day_inactive';
  readonly httpStatus = 422;
  constructor(date: string) {
    super(`Cannot record flights for future date ${date}. Day is not active yet.`);
    this.details = { fields: { date: 'future day inactive' } };
  }
}

export class PastDayCannotAddError extends DomainError {
  readonly code = 'past_day_cannot_add';
  readonly httpStatus = 422;
  constructor(date: string) {
    super(`Cannot add new pigeons to past date ${date}. Past flights can only be edited or deleted.`);
    this.details = { fields: { date: 'past day cannot add' } };
  }
}

