import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CommentService {
  constructor(private prisma: PrismaService) {}

  async getComments(postId: number) {
    const comments = await this.prisma.comment.findMany({
      where: { postId },
      include: {
        user: { select: { id: true, name: true, photo: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return comments.map((c) => ({
      id: c.id.toString(),
      userId: c.userId.toString(),
      userName: c.user.name,
      userPhoto: c.user.photo,
      comment: c.comment,
      createdAt: c.createdAt,
      time: c.createdAt.toISOString(),
    }));
  }

  async addComment(postId: number, userId: number, comment: string) {
    const newComment = await this.prisma.comment.create({
      data: {
        postId,
        userId,
        comment,
      },
      include: {
        user: { select: { id: true, name: true, photo: true } },
      },
    });

    return {
      id: newComment.id.toString(),
      userId: newComment.userId.toString(),
      userName: newComment.user.name,
      userPhoto: newComment.user.photo,
      comment: newComment.comment,
      createdAt: newComment.createdAt,
    };
  }
}
