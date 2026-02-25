import AppKit
import SwiftUI

@MainActor
@Observable
final class OCRViewModel {
    var capturedImage: NSImage?
    var recognizedText: String = ""
    var translatedText: String = ""
    var isProcessing: Bool = false
    var isTranslating: Bool = false
    var errorMessage: String?
    var showSelectionOverlay: Bool = false
    
    var sourceLanguage: Language = .auto
    var targetLanguage: Language = .chinese
    
    // 记录上次使用的截图方式
    private var lastCaptureType: CaptureType = .fullScreen
    private var lastCaptureRect: CGRect?
    
    enum CaptureType {
        case fullScreen
        case region
    }
    
    private let screenshotCapture = ScreenshotCapture.shared
    private let ocrService = OCRService.shared
    private let translationService = TranslationService.shared
    private let storageService = StorageService.shared
    private let clipboardService = ClipboardService.shared
    
    var hasScreenRecordingPermission: Bool {
        get async {
            await screenshotCapture.checkScreenRecordingPermission()
        }
    }
    
    func requestScreenRecordingPermission() async {
        await screenshotCapture.requestScreenRecordingPermission()
    }
    
    func captureAndRecognize() async {
        NSLog("开始执行全屏截图和识别")
        // 记录上次使用的截图方式
        lastCaptureType = .fullScreen
        lastCaptureRect = nil
        
        isProcessing = true
        errorMessage = nil
        capturedImage = nil
        recognizedText = ""
        translatedText = ""
        
        do {
            NSLog("开始捕获全屏截图")
            let image = try await screenshotCapture.captureScreen()
            NSLog("截图成功，图像尺寸：%f x %f", image.size.width, image.size.height)
            capturedImage = image
            
            NSLog("开始执行OCR识别")
            let result = try await ocrService.recognizeText(in: image)
            NSLog("OCR识别成功，识别结果：'%@'", result.text)
            recognizedText = result.text
            
            if !recognizedText.isEmpty {
                NSLog("识别结果不为空，开始翻译")
                await translateRecognizedText()
            } else {
                NSLog("识别结果为空")
            }
        } catch {
            NSLog("捕获和识别过程中发生错误：%@", error.localizedDescription)
            errorMessage = error.localizedDescription
        }
        
        isProcessing = false
        NSLog("捕获和识别过程完成")
    }
    
    func captureRegionAndRecognize(rect: CGRect) async {
        NSLog("开始执行区域截图和识别，区域：%@", String(describing: rect))
        // 记录上次使用的截图方式
        lastCaptureType = .region
        lastCaptureRect = rect
        
        isProcessing = true
        errorMessage = nil
        capturedImage = nil
        recognizedText = ""
        translatedText = ""
        
        do {
            NSLog("开始捕获区域截图")
            let image = try await screenshotCapture.captureRegion(rect: rect)
            NSLog("截图成功，图像尺寸：%f x %f", image.size.width, image.size.height)
            capturedImage = image
            
            NSLog("开始执行OCR识别")
            let result = try await ocrService.recognizeText(in: image)
            NSLog("OCR识别成功，识别结果：'%@'", result.text)
            recognizedText = result.text
            
            if !recognizedText.isEmpty {
                NSLog("识别结果不为空，开始翻译")
                await translateRecognizedText()
            } else {
                NSLog("识别结果为空")
            }
        } catch {
            NSLog("捕获和识别过程中发生错误：%@", error.localizedDescription)
            errorMessage = error.localizedDescription
        }
        
        isProcessing = false
        NSLog("捕获和识别过程完成")
    }
    
    func retry() async {
        NSLog("开始执行重试操作，上次捕获方式：%@", lastCaptureType == .fullScreen ? "全屏" : "区域")
        // 根据上次使用的截图方式来决定使用哪种截图方法
        switch lastCaptureType {
        case .fullScreen:
            NSLog("重试全屏截图")
            await captureAndRecognize()
        case .region:
            if let rect = lastCaptureRect {
                NSLog("重试区域截图，区域：%@", String(describing: rect))
                await captureRegionAndRecognize(rect: rect)
            } else {
                NSLog("没有上次的区域信息，默认使用全屏截图")
                await captureAndRecognize()
            }
        }
    }
    
    func translateRecognizedText() async {
        guard !recognizedText.isEmpty else { return }
        
        isTranslating = true
        
        do {
            let result = try await translationService.translate(
                text: recognizedText,
                from: sourceLanguage,
                to: targetLanguage
            )
            translatedText = result
            
            let history = TranslationHistory(
                sourceText: recognizedText,
                translatedText: result,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            )
            await storageService.addToHistory(history)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isTranslating = false
    }
    
    func copyRecognizedText() async {
        guard !recognizedText.isEmpty else { return }
        await clipboardService.copy(recognizedText)
    }
    
    func copyTranslatedText() async {
        guard !translatedText.isEmpty else { return }
        await clipboardService.copy(translatedText)
    }
    
    func clear() {
        capturedImage = nil
        recognizedText = ""
        translatedText = ""
        errorMessage = nil
    }
}
