import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UserService {
  constructor(private prisma: PrismaService) {}

  async getUserProfile(profile_id: string, current_user_id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: parseInt(profile_id) },
      include: {
        _count: { select: { posts: true, followers: true, following: true } }
      }
    });
    if (!user) {
      throw new NotFoundException('المستخدم غير موجود');
    }
    const isFollowing = await this.prisma.follower.findUnique({
      where: {
        followerId_followingId: {
          followerId: parseInt(current_user_id),
          followingId: parseInt(profile_id)
        }
      }
    });

    return {
      user: {
        id: user.id.toString(),
        name: user.name,
        username: user.username,
        email: user.email,
        photo: user.photo,
        bio: user.bio,
        stats: {
          posts: user._count.posts,
          followers: user._count.followers,
          following: user._count.following
        },
        isFollowing: !!isFollowing
      }
    };
  }

  async toggleFollow(user_id: string, profile_id: string) {
    const uid = parseInt(user_id);
    const pid = parseInt(profile_id);
    const existingFollow = await this.prisma.follower.findUnique({
      where: { followerId_followingId: { followerId: uid, followingId: pid } }
    });
    if (existingFollow) {
      await this.prisma.follower.delete({ where: { id: existingFollow.id } });
      return { message: 'Unfollowed' };
    } else {
      await this.prisma.follower.create({ data: { followerId: uid, followingId: pid } });
      return { message: 'Followed' };
    }
  }

  async searchUsers(q: string, current_user_id: string) {
    return this.prisma.user.findMany({
      where: {
        OR: [
          { name: { contains: q, mode: 'insensitive' } },
          { username: { contains: q, mode: 'insensitive' } }
        ],
        NOT: { id: parseInt(current_user_id) }
      },
      take: 20
    });
  }

  async getSuggestedUsers(current_user_id: string) {
    return this.prisma.user.findMany({
      where: { NOT: { id: parseInt(current_user_id) } },
      take: 5
    });
  }

  async getUserStats(userId: string) {
    const uid = parseInt(userId);
    const postsCount = await this.prisma.post.count({ where: { userId: uid } });
    const followersCount = await this.prisma.follower.count({ where: { followingId: uid } });
    const followingCount = await this.prisma.follower.count({ where: { followerId: uid } });
    
    // Count total likes on user's posts
    const likesCount = await this.prisma.like.count({
      where: { post: { userId: uid } }
    });

    // Count total comments on user's posts
    const commentsCount = await this.prisma.comment.count({
      where: { post: { userId: uid } }
    });

    // Count saved posts by user
    const savedCount = await this.prisma.savedPost.count({ where: { userId: uid } });

    return {
      posts: postsCount,
      followers: followersCount,
      following: followingCount,
      likes: likesCount,
      comments: commentsCount,
      saved: savedCount,
      engagementRate: postsCount > 0 ? ((likesCount + commentsCount) / postsCount).toFixed(1) : '0.0'
    };
  }
}
