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

  private connectedUsers = new Map<string, string>(); // socketId -> userId

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
    this.connectedUsers.delete(client.id);
  }

  @SubscribeMessage('join')
  handleJoin(
    @MessageBody() userId: string,
    @ConnectedSocket() client: Socket,
  ) {
    this.connectedUsers.set(client.id, userId);
    client.join(`user_${userId}`);
    console.log(`User ${userId} joined with socket ${client.id}`);
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
}
