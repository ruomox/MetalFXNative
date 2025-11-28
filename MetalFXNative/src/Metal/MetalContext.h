//
//  MetalContext.h
//  MetalFXNative
//
//  Created by Mox on 2025/10/17.
//

#pragma once
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#ifdef __cplusplus
extern "C" {
#endif

/// 初始化 Metal 设备与命令队列
bool MetalContext_Initialize(void);

/// 获取全局 Metal 设备
id<MTLDevice> MetalContext_GetDevice(void);

/// 获取全局命令队列
id<MTLCommandQueue> MetalContext_GetCommandQueue(void);

/// 创建普通 2D 纹理
id<MTLTexture> MetalContext_CreateTexture2D(int width, int height, MTLPixelFormat format);

/// 检查设备是否支持 MetalFX
bool MetalContext_IsMetalFXSupported(void);

/// 关闭 Metal 并释放资源
void MetalContext_Shutdown(void);

#ifdef __cplusplus
}
#endif
