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
    
    func recognizeText(in image: NSImage, languages: [String] = ["zh-Hans", "zh-Hant", "en"]) async throws -> OCRResult {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.imageConversionFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation],
                      !observations.isEmpty else {
                    continuation.resume(throwing: OCRError.noTextDetected)
                    return
                }
                
                var fullText = ""
                var boundingBoxes: [OCRResult.BoundingBox] = []
                
                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else {
                        continue
                    }
                    
                    let text = topCandidate.string
                    fullText += text + "\n"
                    
                    let boundingBox = OCRResult.BoundingBox(
                        text: text,
                        rect: observation.boundingBox,
                        confidence: topCandidate.confidence
                    )
                    boundingBoxes.append(boundingBox)
                }
                
                let result = OCRResult(
                    text: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
                    boundingBoxes: boundingBoxes
                )
                
                continuation.resume(returning: result)
            }
            
            request.recognitionLanguages = languages
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error))
            }
        }
    }
    
    func recognizeText(in cgImage: CGImage, languages: [String] = ["zh-Hans", "zh-Hant", "en"]) async throws -> OCRResult {
        let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        return try await recognizeText(in: image, languages: languages)
    }
}
