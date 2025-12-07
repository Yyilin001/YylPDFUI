//
//  PDFPageChangeSwipeGestureRecognizer.swift
//  PDFUI
//
//  Created by yyl on 2025/12/7.
//

import PDFKit
import UIKit

class TwoUpGestureRecognizer: UIPanGestureRecognizer {
    unowned let pdfView: PDFView
    private var lastBoundsOrigin: CGPoint = .zero
    init(pdfView: PDFView) {
        self.pdfView = pdfView
        super.init(target: nil, action: nil)
        addTarget(self, action: #selector(handlePan(_:)))
    }

    @objc
    private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let docUIView = pdfView.documentView else { return }

        let translation = gesture.translation(in: pdfView)

        switch gesture.state {
        case .began:
            lastBoundsOrigin = docUIView.frame.origin
        case .changed:
            var newOrigin = lastBoundsOrigin
            if pdfView.displayDirection == .horizontal {
                newOrigin.x = lastBoundsOrigin.x + translation.x
            } else {
                newOrigin.y = lastBoundsOrigin.y + translation.y
            }
            docUIView.frame.origin = newOrigin
        case .ended, .cancelled, .failed:
            let threshold: CGFloat = 150
            if pdfView.displayDirection == .horizontal {
                if translation.x < -threshold, pdfView.canGoToNextPage {
                    pdfView.goToNextPage(nil)
                } else if translation.x > threshold, pdfView.canGoToPreviousPage {
                    pdfView.goToPreviousPage(nil)
                }
            } else {
                if translation.y < -threshold, pdfView.canGoToNextPage {
                    pdfView.goToNextPage(nil)
                } else if translation.y > threshold, pdfView.canGoToPreviousPage {
                    pdfView.goToPreviousPage(nil)
                }
            }
            // 无论是否翻页，恢复 documentView.frame.origin
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
                self.pdfView.layoutDocumentView()
            }
        default:
            break
        }
    }
}
