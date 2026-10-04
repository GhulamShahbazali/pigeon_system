export interface UserRecord {
  id: string;
  displayName: string;
  username: string;
  photoUrl: string | null;
  bio: string | null;
  city: string | null;
  countryCode: string | null;
  languageCode: string;
  role: string;
  isSuspended: boolean;
  followerCount: number;
  followingCount: number;
  createdAt: Date;
}

export interface DeviceInput {
  deviceId: string;
  deviceType: 'android' | 'ios';
  fcmToken?: string;
  appVersion?: string;
}

export interface NewUserInput {
  provider: 'google' | 'apple';
  providerId: string;
  email?: string;
  displayName: string;
  username: string;
  languageCode: string;
  photoUrl?: string;
  timezone?: string;
  countryCode?: string;
}

export interface IAuthRepository {
  findByProvider(provider: string, providerId: string): Promise<UserRecord | null>;
  findById(id: string): Promise<UserRecord | null>;
  usernameTaken(username: string): Promise<boolean>;
  createUserWithDefaults(input: NewUserInput, device: DeviceInput): Promise<UserRecord>;
  upsertDevice(userId: string, device: DeviceInput): Promise<string>; // returns device id
  deleteDevice(userId: string, deviceRowId: string): Promise<void>;
  deleteAllDevices(userId: string): Promise<void>;
  touchActive(userId: string): Promise<void>;
}

export const AUTH_REPOSITORY = Symbol('AUTH_REPOSITORY');
