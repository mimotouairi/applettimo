import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Injectable } from '@nestjs/common';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
@Injectable()
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private socketToUser = new Map<string, string>(); // socketId -> userId
  private userToSockets = new Map<string, Set<string>>(); // userId -> socketIds

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
    const userId = this.socketToUser.get(client.id);
    if (!userId) return;

    this.socketToUser.delete(client.id);
    const sockets = this.userToSockets.get(userId);
    if (!sockets) return;
    sockets.delete(client.id);
    if (sockets.size === 0) {
      this.userToSockets.delete(userId);
    }
  }

  @SubscribeMessage('join')
  handleJoin(
    @MessageBody() userId: string,
    @ConnectedSocket() client: Socket,
  ) {
    const normalizedUserId = String(userId ?? '').trim();
    if (!normalizedUserId) return;

    const existingUserId = this.socketToUser.get(client.id);
    if (existingUserId === normalizedUserId) {
      // Ignore duplicate join for same socket/user pair.
      return;
    }

    if (existingUserId != null && existingUserId != normalizedUserId) {
      client.leave(`user_${existingUserId}`);
      const oldSet = this.userToSockets.get(existingUserId);
      oldSet?.delete(client.id);
      if (oldSet != null && oldSet.size == 0) {
        this.userToSockets.delete(existingUserId);
      }
    }

    this.socketToUser.set(client.id, normalizedUserId);
    if (!this.userToSockets.has(normalizedUserId)) {
      this.userToSockets.set(normalizedUserId, new Set<string>());
    }
    this.userToSockets.get(normalizedUserId)!.add(client.id);

    client.join(`user_${normalizedUserId}`);
    console.log(`User ${normalizedUserId} joined with socket ${client.id}`);
  }

  @SubscribeMessage('send_message')
  handleMessage(@MessageBody() data: any) {
    const { receiverId, message } = data;
    this.emitMessage(receiverId, message);
  }

  emitMessage(receiverId: string, message: any) {
    this.server.to(`user_${receiverId}`).emit('new_message', message);
  }

  @SubscribeMessage('typing')
  handleTyping(@MessageBody() data: any) {
    const { receiverId, senderId, isTyping } = data;
    this.server.to(`user_${receiverId}`).emit('user_typing', { senderId, isTyping });
  }

  emitNotification(receiverId: string, notification: any) {
    this.server.to(`user_${receiverId}`).emit('new_notification', notification);
  }
}
