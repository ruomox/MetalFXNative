//
//  Logger.h
//  MetalFXNative
//
//  Created by Mox on 2025/10/17.
//

#pragma once
#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

/// @brief 输出信息日志（支持多语言）
/// @param tag 模块名（如 "MetalContext"）
/// @param msgKey 语言键值（或原文）
void LOG_INFO(const char* tag, const char* msgKey);

/// @brief 输出警告日志（支持多语言）
/// @param tag 模块名
/// @param msgKey 语言键值
void LOG_WARN(const char* tag, const char* msgKey);

/// @brief 输出错误日志（支持多语言）
/// @param tag 模块名
/// @param msgKey 语言键值
void LOG_ERROR(const char* tag, const char* msgKey);

#ifdef __cplusplus
}
#endif
