import AppKit
import Foundation
import Vision

struct OCRResult {
    let text: String
    let boundingBoxes: [BoundingBox]
    
    struct BoundingBox {
        let text: String
        let rect: CGRect
        let confidence: Float
    }
}

enum OCRError: Error, LocalizedError {
    case noTextDetected
    case imageConversionFailed
    case recognitionFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .noTextDetected:
            return "未检测到文字"
        case .imageConversionFailed:
            return "图像转换失败"
        case .recognitionFailed(let error):
            return "识别失败: \(error.localizedDescription)"
        }
    }
}

actor OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    func recognizeText(in image: NSImage, languages: [String] = ["zh-Hans", "zh-Hant", "en", "ja", "ko", "fr", "de", "es", "it", "ru"]) async throws -> OCRResult {
        NSLog("OCR 识别开始：")
        NSLog("图像尺寸：%f x %f", image.size.width, image.size.height)
        NSLog("图像表示：%@", image.description)
        
        // 尝试多种方式获取 CGImage
        var cgImage: CGImage? = nil
        
        // 第一种方式：直接获取
        cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        if cgImage != nil {
            NSLog("成功通过直接方式获取 CGImage")
        } else {
            NSLog("直接方式获取 CGImage 失败，尝试第二种方式")
            // 第二种方式：通过 bitmap 上下文
            if let tiffData = image.tiffRepresentation {
                NSLog("成功获取 TIFF 数据，长度：%d", tiffData.count)
                if let bitmapImageRep = NSBitmapImageRep(data: tiffData) {
                    NSLog("成功创建 bitmap image rep")
                    NSLog("bitmap image rep 尺寸：%dx%d", bitmapImageRep.pixelsWide, bitmapImageRep.pixelsHigh)
                    cgImage = bitmapImageRep.cgImage
                    if cgImage != nil {
                        NSLog("成功通过 bitmap 方式获取 CGImage")
                    } else {
                        NSLog("bitmap image rep 没有 CGImage")
                    }
                } else {
                    NSLog("创建 bitmap image rep 失败")
                }
            } else {
                NSLog("获取 TIFF 数据失败")
            }
        }
        
        guard let finalCGImage = cgImage else {
            NSLog("所有方式获取 CGImage 都失败")
            throw OCRError.imageConversionFailed
        }
        
        NSLog("CGImage 尺寸：%d x %d", finalCGImage.width, finalCGImage.height)
        NSLog("识别语言：%@", languages.description)
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    NSLog("识别错误：%@", error.localizedDescription)
                    NSLog("错误类型：%@", String(describing: type(of: error)))
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    NSLog("未检测到文字，结果类型错误：%@", String(describing: type(of: request.results)))
                    continuation.resume(throwing: OCRError.noTextDetected)
                    return
                }
                
                NSLog("检测到 %d 个文字区域", observations.count)
                
                var fullText = ""
                var boundingBoxes: [OCRResult.BoundingBox] = []
                
                for (index, observation) in observations.enumerated() {
                    NSLog("处理文字区域 %d/%d", index + 1, observations.count)
                    
                    let candidates = observation.topCandidates(5)
                    NSLog("区域 %d 有 %d 个候选结果", index + 1, candidates.count)
                    
                    for (candidateIndex, candidate) in candidates.enumerated() {
                        NSLog("  候选 %d: '%@', 置信度：%f", candidateIndex + 1, candidate.string, candidate.confidence)
                    }
                    
                    guard let topCandidate = candidates.first else {
                        NSLog("区域 %d 没有候选结果", index + 1)
                        continue
                    }
                    
                    let text = topCandidate.string
                    // 过滤掉空字符串
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        fullText += text + "\n"
                        
                        NSLog("识别到文字：'%@', 置信度：%f", text, topCandidate.confidence)
                        
                        let boundingBox = OCRResult.BoundingBox(
                            text: text,
                            rect: observation.boundingBox,
                            confidence: topCandidate.confidence
                        )
                        boundingBoxes.append(boundingBox)
                    } else {
                        NSLog("过滤掉空字符串")
                    }
                }
                
                let trimmedText = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
                NSLog("最终识别结果：'%@'", trimmedText)
                NSLog("识别结果长度：%d", trimmedText.count)
                
                // 确保结果不为空
                guard !trimmedText.isEmpty else {
                    NSLog("识别结果为空字符串")
                    continuation.resume(throwing: OCRError.noTextDetected)
                    return
                }
                
                let result = OCRResult(
                    text: trimmedText,
                    boundingBoxes: boundingBoxes
                )
                
                NSLog("OCR 识别完成，返回结果")
                continuation.resume(returning: result)
            }
            
            request.recognitionLanguages = languages
            // 使用 accurate 模式以提高识别准确率
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            // 允许识别更多文字，包括低置信度的结果
            request.minimumTextHeight = 0.005 // 进一步减小最小文字高度
            
            NSLog("准备执行 OCR 请求")
            NSLog("请求配置：")
            NSLog("  识别语言：%@", request.recognitionLanguages.description)
            NSLog("  识别级别：%@", String(describing: request.recognitionLevel))
            NSLog("  使用语言纠正：%d", request.usesLanguageCorrection)
            NSLog("  最小文字高度：%f", request.minimumTextHeight)
            
            let handler = VNImageRequestHandler(cgImage: finalCGImage, options: [:])
            
            do {
                NSLog("执行 OCR 请求")
                try handler.perform([request])
                NSLog("OCR 请求执行成功")
            } catch {
                NSLog("OCR 请求执行失败：%@", error.localizedDescription)
                NSLog("失败错误类型：%@", String(describing: type(of: error)))
                continuation.resume(throwing: OCRError.recognitionFailed(error))
            }
        }
    }
    
    func recognizeText(in cgImage: CGImage, languages: [String] = ["zh-Hans", "zh-Hant", "en", "ja", "ko", "fr", "de", "es", "it", "ru"]) async throws -> OCRResult {
        let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        return try await recognizeText(in: image, languages: languages)
    }
}
