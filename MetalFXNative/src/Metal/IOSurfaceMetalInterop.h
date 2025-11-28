//
//  IOSurfaceMetalInterop.h
//  MetalFXNative
//
//  Created by Mox on 2025/10/27.
//

#pragma once
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

// 前向声明
struct IOSurface;
typedef struct __IOSurface* IOSurfaceRef;

#ifdef __cplusplus
extern "C" {
#endif

/// 从 IOSurface 创建 Metal 纹理
id<MTLTexture> IOSurfaceMetalInterop_CreateTextureFromSurface(IOSurfaceRef surface, id<MTLDevice> device);

/// 检查 IOSurface 格式是否与 Metal 兼容
bool IOSurfaceMetalInterop_IsFormatCompatible(IOSurfaceRef surface);

/// 获取 IOSurface 的像素格式
uint32_t IOSurfaceMetalInterop_GetPixelFormat(IOSurfaceRef surface);

/// 获取 IOSurface 的尺寸
void IOSurfaceMetalInterop_GetDimensions(IOSurfaceRef surface, int* width, int* height);

#ifdef __cplusplus
}
#endif