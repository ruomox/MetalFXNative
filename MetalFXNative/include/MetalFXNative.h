//
//  MetalFXNative.h
//  MetalFXNative
//
//  Created by Mox on 2025/10/17.
//

#pragma once
#import <Foundation/Foundation.h>

//! Project version number for MetalFXNative.
FOUNDATION_EXPORT double MetalFXNativeVersionNumber;

//! Project version string for MetalFXNative.
FOUNDATION_EXPORT const unsigned char MetalFXNativeVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MetalFXNative/PublicHeader.h>

#ifdef __cplusplus
extern "C" {
#endif

/// 初始化 MetalFXNative 环境
bool MetalFXNative_Init(void);

/// 创建一个 IOSurface
void* MetalFXNative_CreateSurface(size_t width, size_t height);

/// 释放指定的 IOSurface
void MetalFXNative_ReleaseSurface(void* surface);

/// 关闭 MetalFXNative 并释放所有资源
void MetalFXNative_Shutdown(void);


/// 设置当前会话的语言代码
/// @param languageCode 语言代码 (如 "zh", "en")
/// @return 如果设置成功返回true，否则false
bool MetalFXNative_SetLanguage(const char* languageCode);

/// 设置外部语言文件路径
/// @param externalPath 外部语言文件路径（可为NULL，使用默认路径）
/// @return 操作是否成功
bool MetalFXNative_SetExternalLanguagePath(const char* externalPath);

#ifdef __cplusplus
}
#endif
