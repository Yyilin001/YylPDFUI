//
//  PDFThumbnailKitView.swift
//  PDFUI
//
//  Created by yyl on 2025/12/7.
//


import PDFKit
import SwiftUI
import UIKit
import PencilKit
internal import os

struct PDFThumbnailKitView: UIViewRepresentable {
    let pdfView: PDFView
    var thumbnailSize: CGSize = CGSize(width: 8, height: 10)
    var layoutMode: PDFThumbnailLayoutMode = .vertical
    var contentInset: UIEdgeInsets = .zero

    func makeUIView(context: Context) -> PDFThumbnailView {
        let thumbnailView = PDFThumbnailView()
        thumbnailView.pdfView = pdfView
        thumbnailView.thumbnailSize = thumbnailSize
        thumbnailView.layoutMode = layoutMode
        thumbnailView.contentInset = contentInset
        thumbnailView.backgroundColor = UIColor.clear
        return thumbnailView
    }

    func updateUIView(_ uiView: PDFThumbnailView, context: Context) {
        // 如果需要在 SwiftUI 动态修改 pdfView 或 thumbnailSize，可在这里更新
        uiView.pdfView = pdfView
        uiView.thumbnailSize = thumbnailSize
        uiView.layoutMode = layoutMode
        uiView.contentInset = contentInset
    }
}
