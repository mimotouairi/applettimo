import { Injectable, ConflictException, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcryptjs';
import * as jwt from 'jsonwebtoken';
import { CloudinaryService } from '../cloudinary/cloudinary.service';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private cloudinary: CloudinaryService
  ) {}

  async register(data: any) {
    const { name, email, password, phone, photo, username } = data;
    const existingUser = await this.prisma.user.findFirst({
      where: { OR: [{ email }, { username }] }
    });
    if (existingUser) {
      throw new ConflictException('المستخدم موجود بالفعل');
    }
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await this.prisma.user.create({
      data: {
        name,
        username: username || email.split('@')[0],
        email,
        password: hashedPassword,
        phone,
        photo,
      }
    });
    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET || 'secret', { expiresIn: '7d' });
    return {
      id: user.id.toString(),
      name: user.name,
      username: user.username,
      email: user.email,
      photo: user.photo,
      coverPhoto: user.coverPhoto,
      bio: user.bio,
      profileLinks: user.profileLinks,
      tags: user.tags,
      musicTrack: user.musicTrack,
      token,
    };
  }

  async login(login_id: string, password: string) {
    const user = await this.prisma.user.findFirst({
      where: { OR: [{ email: login_id }, { username: login_id }] }
    });
    if (!user) {
      throw new NotFoundException('المستخدم غير موجود');
    }
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      throw new UnauthorizedException('كلمة المرور غير صحيحة');
    }
    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET || 'secret', { expiresIn: '7d' });
    return {
      id: user.id.toString(),
      name: user.name,
      username: user.username,
      email: user.email,
      photo: user.photo,
      coverPhoto: user.coverPhoto,
      bio: user.bio,
      profileLinks: user.profileLinks,
      tags: user.tags,
      musicTrack: user.musicTrack,
      token,
    };
  }

  async updateProfileWithCloudinary(data: any, file?: Express.Multer.File) {
    try {
      const { user_id, name, bio, phone } = data;
      console.log(`[AuthService] Updating profile for user: ${user_id}`);
      let photoUrl = data.photo;

      if (file) {
        const result = await this.cloudinary.uploadFile(file);
        photoUrl = result.secure_url;
      }

      const user = await this.prisma.user.update({
        where: { id: parseInt(user_id) },
        data: { name, bio, phone, photo: photoUrl }
      });
      
      console.log(`[AuthService] Profile updated successfully for user: ${user_id}`);
      return {
        id: user.id,
        name: user.name,
        username: user.username,
        email: user.email,
        bio: user.bio,
        photo: user.photo,
        coverPhoto: user.coverPhoto,
        profileLinks: user.profileLinks,
        tags: user.tags,
        musicTrack: user.musicTrack,
      };
    } catch (error) {
      console.error('[AuthService] Error updating profile:', error);
      throw error;
    }
  }

  async updateProfileV2WithCloudinary(data: any, files: { photo?: Express.Multer.File[], coverPhoto?: Express.Multer.File[] }) {
    try {
      const { user_id, name, bio, phone, profileLinks, tags, musicTrack, musicTitle } = data;
      console.log(`[AuthService] Updating profile V2 for user: ${user_id}`);
      let photoUrl = data.photo;
      let coverPhotoUrl = data.coverPhoto;

      if (files.photo && files.photo[0]) {
        const result = await this.cloudinary.uploadFile(files.photo[0]);
        photoUrl = result.secure_url;
      }

      if (files.coverPhoto && files.coverPhoto[0]) {
        const result = await this.cloudinary.uploadFile(files.coverPhoto[0]);
        coverPhotoUrl = result.secure_url;
      }

      const user = await this.prisma.user.update({
        where: { id: parseInt(user_id) },
        data: {
          name,
          bio,
          phone,
          photo: photoUrl,
          coverPhoto: coverPhotoUrl,
          profileLinks: Array.isArray(profileLinks) ? profileLinks : [],
          tags: Array.isArray(tags) ? tags : [],
          musicTrack,
          musicTitle,
        },
      });

      console.log(`[AuthService] Profile V2 updated successfully for user: ${user_id}`);
      return {
        id: user.id,
        name: user.name,
        username: user.username,
        email: user.email,
        bio: user.bio,
        photo: user.photo,
        coverPhoto: user.coverPhoto,
        profileLinks: user.profileLinks,
        tags: user.tags,
        musicTrack: user.musicTrack,
        musicTitle: user.musicTitle,
      };
    } catch (error) {
      console.error('[AuthService] Error updating profile V2:', error);
      throw error;
    }
  }

  async updateProfile(data: any) {
    return this.updateProfileWithCloudinary(data);
  }

  async updateProfileV2(data: any) {
    return this.updateProfileV2WithCloudinary(data, {});
  }

  async switchAccount(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: parseInt(userId) },
    });
    if (!user) {
      throw new NotFoundException('المستخدم غير موجود');
    }
    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET || 'secret', { expiresIn: '7d' });
    return {
      id: user.id.toString(),
      name: user.name,
      username: user.username,
      email: user.email,
      bio: user.bio,
      photo: user.photo,
      coverPhoto: user.coverPhoto,
      profileLinks: user.profileLinks,
      tags: user.tags,
      musicTrack: user.musicTrack,
      token,
    };
  }
}
