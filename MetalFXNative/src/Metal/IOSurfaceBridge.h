//
//  IOSurfaceBridge.h
//  MetalFXNative
//
//  Created by Mox on 2025/10/17.
//

#pragma once
#import <Foundation/Foundation.h>
#import <IOSurface/IOSurface.h>

#ifdef __cplusplus
extern "C" {
#endif

/// 创建 IOSurface
IOSurfaceRef IOSurfaceBridge_CreateIOSurfaceWithWidth(int width, int height);

/// 锁定 IOSurface 以确保数据一致性
bool IOSurfaceBridge_LockSurface(IOSurfaceRef surface);

/// 解锁 IOSurface
void IOSurfaceBridge_UnlockSurface(IOSurfaceRef surface);

/// 检查 IOSurface 格式是否与 Metal 兼容
bool IOSurfaceBridge_IsFormatCompatible(IOSurfaceRef surface);

/// 获取 IOSurface 的像素格式
OSType IOSurfaceBridge_GetPixelFormat(IOSurfaceRef surface);

/// 获取 IOSurface 的尺寸
void IOSurfaceBridge_GetDimensions(IOSurfaceRef surface, int* width, int* height);

/// 打印 IOSurface 详细信息
void IOSurfaceBridge_LogInfo(IOSurfaceRef surface);

/// 释放 IOSurface
void IOSurfaceBridge_Release(IOSurfaceRef surface);

#ifdef __cplusplus
}
#endif
