import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import {
  DeviceInput,
  IAuthRepository,
  NewUserInput,
  UserRecord,
} from '../domain/auth.repository';

const userSelect = {
  id: true,
  displayName: true,
  username: true,
  photoUrl: true,
  bio: true,
  city: true,
  countryCode: true,
  languageCode: true,
  role: true,
  isSuspended: true,
  followerCount: true,
  followingCount: true,
  createdAt: true,
} as const;

@Injectable()
export class PrismaAuthRepository implements IAuthRepository {
  constructor(private readonly prisma: PrismaService) {}

  findByProvider(provider: string, providerId: string): Promise<UserRecord | null> {
    return this.prisma.user.findFirst({
      where: { authProvider: provider as any, authProviderId: providerId, deletedAt: null },
      select: userSelect,
    });
  }

  findById(id: string): Promise<UserRecord | null> {
    return this.prisma.user.findFirst({ where: { id, deletedAt: null }, select: userSelect });
  }

  async usernameTaken(username: string): Promise<boolean> {
    const n = await this.prisma.user.count({ where: { username } });
    return n > 0;
  }

  async createUserWithDefaults(input: NewUserInput, device: DeviceInput): Promise<UserRecord> {
    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          authProvider: input.provider,
          authProviderId: input.providerId,
          email: input.email,
          displayName: input.displayName,
          username: input.username.toLowerCase(),
          languageCode: input.languageCode,
          photoUrl: input.photoUrl,
          timezone: input.timezone ?? 'Asia/Karachi',
          countryCode: input.countryCode,
          notifPrefs: { create: {} },
          privacyPrefs: { create: {} },
          appPrefs: { create: { languageCode: input.languageCode } },
          devices: {
            create: {
              deviceId: device.deviceId,
              deviceType: device.deviceType,
              fcmToken: device.fcmToken,
              appVersion: device.appVersion,
            },
          },
        },
        select: userSelect,
      });
      return user;
    });
  }

  async upsertDevice(userId: string, device: DeviceInput): Promise<string> {
    const row = await this.prisma.userDevice.upsert({
      where: { userId_deviceId: { userId, deviceId: device.deviceId } },
      create: {
        userId,
        deviceId: device.deviceId,
        deviceType: device.deviceType,
        fcmToken: device.fcmToken,
        appVersion: device.appVersion,
      },
      update: {
        fcmToken: device.fcmToken,
        appVersion: device.appVersion,
        lastUsedAt: new Date(),
      },
      select: { id: true },
    });
    return row.id;
  }

  async deleteDevice(userId: string, deviceRowId: string): Promise<void> {
    await this.prisma.userDevice.deleteMany({ where: { id: deviceRowId, userId } });
  }

  async deleteAllDevices(userId: string): Promise<void> {
    await this.prisma.userDevice.deleteMany({ where: { userId } });
  }

  async touchActive(userId: string): Promise<void> {
    await this.prisma.user.update({ where: { id: userId }, data: { lastActiveAt: new Date() } });
  }
}
