//
//  NetADSBDecoder.swift
//  Net1090
//
//  Created by Jacky Jack on 19/07/2024.
//

import Foundation
import Network
import NIO

protocol ADSBQueueDelegate: AnyObject {
    var message_array:Array<String> {get set}
}

class NetADSBHandlder: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    var messageDelegate: ADSBQueueDelegate?
    
    func channelActive(context: ChannelHandlerContext) {
        print("Channel is active")
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        let readableBytes = buffer.readableBytes
        if let received =  buffer.readString(length: readableBytes) {
            //print(received,terminator: "")
            /*
            if let message_queue = message_queue {
                message_queue.append(String(received))
                print("Add new messsge")
            }*/
            //if self.message_array != nil {
            //    message_array?.append(String(received))
            //    print("\(message_array?.count)")
            //}
            if self.messageDelegate != nil {
                if received.count == 17 {
                    let trimmed = received.trimmingCharacters(in: .newlines).lowercased()
                    messageDelegate?.message_array.append(String(trimmed))
                    
                } else if received.count == 31  {
                    let trimmed = received.trimmingCharacters(in: .newlines).lowercased()
                    messageDelegate?.message_array.append(String(trimmed))
                } else {
                    for line in received.components(separatedBy: .newlines) {
                        let trimmed = line.trimmingCharacters(in: .newlines).lowercased()
                        messageDelegate?.message_array.append(String(trimmed))
                    }
                }
            }
        }
    }
    
    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        print("error: \(error.localizedDescription)")
        context.close(promise: nil)
    }
}

class ADSBQueue: ADSBQueueDelegate {
    var message_array:Array<String> = []
}

class NetADSBDecoder {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    var host: String
    var port: Int
    
    var msgarray = ADSBQueue()
    var handler = NetADSBHandlder()
    //var msg_array:Array<String> = []
    
    init(host: String, port: Int) {
        self.host = host
        self.port = port
        //regiter delegate
        handler.messageDelegate = msgarray
    }
    
    func start() throws {
        do {
            let channel = try ClientBootstrap(group: group)
                .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
                .channelInitializer{channel in
                    //channel.pipeline.add(handler: ADSBHandlder())
                    channel.pipeline.addHandlers([self.handler])
                }.connect(host: self.host, port: self.port)
                .wait()
            try channel.closeFuture.wait()
        } catch let error {
            print(error)
            throw error
        }
    }
    
    func stop()  {
        do {
            try group.syncShutdownGracefully()
        } catch let error {
            print("Error shutting down \(error.localizedDescription)")
            exit(0)
        }
        print("Connection closed")
    }
}
