//
//  PDFThumbnail.swift
//  PDFUI
//
//  Created by yyl on 2025/12/7.
//


import PDFKit
import SwiftUI
import UIKit
import PencilKit
internal import os

/// PDF 缩略图信息
struct PDFThumbnail {
    let pageIndex: Int   // 页码索引
    let image: UIImage   // 对应缩略图
}
