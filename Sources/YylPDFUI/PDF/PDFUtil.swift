//
//  PDFUtil.swift
//  sdfsafw
//
//  Created by Yyl on 2025/9/12.
//

import Foundation
import PDFKit
internal import os
struct PDF{
   static func generatePDFThumbnail(from pdfDocument: PDFDocument, pageIndex: Int = 0, size: CGSize) -> UIImage? {
        guard let page = pdfDocument.page(at: pageIndex) else {
            log.debug("无法获取指定页面")
            return nil
        }

        // 生成缩略图
        let thumbnail = page.thumbnail(of: size, for: .mediaBox)
        return thumbnail
    }
}


