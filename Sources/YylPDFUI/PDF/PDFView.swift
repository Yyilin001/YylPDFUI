//
//  SwiftUIView.swift
//  Mypdf
//
//  Created by Yyl on 2025/9/11.
//

import PDFKit
import SwiftUI
import UIKit
import Combine
internal import os
nonisolated let log = Logger(subsystem: "Yyl", category: "PDF")
@MainActor
struct YylPDFView: UIViewRepresentable {
    @Environment(PDFProxy.self) private var proxy: PDFProxy

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
   
        if let document = proxy.pdfDocument {
            //配置pdf文档和文档代理
            //设置pdf当前页跟踪
            setDocAndDelegate(pdfView: pdfView, document: document)
            setProxyStatus(pdfView)
        }
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
     
        
        return pdfView
    }
    
    //页面绑定的值发生变化才会触发updateUIView
    func updateUIView(_ pdfView: PDFView, context: Context) {
        //如果文档对象不一致，则尝试设置文档
        if pdfView.document !== proxy.pdfDocument {
            if let document = proxy.pdfDocument {
                Task { @MainActor in
                    setDocAndDelegate(pdfView: pdfView, document: document)
                    setProxyStatus(pdfView)
                }
            } else {
                log.debug("PDF document is nil!")
            }
        }
    }
}

extension YylPDFView{
    
    //设置PDFDocument和delegate
    private func setDocAndDelegate(pdfView: PDFView,document: PDFDocument){
        pdfView.document = document
 
    }
    
    //设置代理的初始状态
    private func setProxyStatus(_ pdfView: PDFView){
        proxy.setPDFView(pdfView)
        proxy.trackCurrentPage(pdfView)
    }
}

