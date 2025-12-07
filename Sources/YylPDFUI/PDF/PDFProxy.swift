import PDFKit
import PencilKit
import SwiftUI
import UIKit
internal import os
@MainActor
@Observable
final class PDFProxy: NSObject {
    var pdfTwoUpGestureRecognizer: TwoUpGestureRecognizer?
    /// PDF文档
    var pdfDocument: PDFDocument?

    /// 持有pdfDocumnet在View中的PDFView
    /// 只有被页面持有的值发生变化才会触发updateUIView，所以需要持有PDFView
    internal private(set) weak var pdfView: PDFView?

    /// 当前页的索引
    var currentIndex: Int = 0

    /// PDF文档最大索引
    var maxIndex: Int = 0

    /// 设置PDFView
    func setPDFView(_ pdfView: PDFView) {
        self.pdfView = pdfView
        setPDFMaxIndex()
    }

    /// 设置PDF最大索引
    @discardableResult
    func setPDFMaxIndex() -> Bool {
        guard let pdfView = pdfView else {
            return false
        }

        if let pageCount = pdfView.document?.pageCount {
            maxIndex = pageCount - 1
            return true
        }

        return false
    }

    // MARK: - 跟踪当前PDF页面

    @ObservationIgnored
    private var pageIndexTask: Task<Void, Never>?

    /// 跟踪PDF页面变化
    func trackCurrentPage(_ pdfView: PDFView) {
        // 取消已有任务
        pageIndexTask?.cancel()

        pageIndexTask = Task {
            for await notification in NotificationCenter.default.notifications(named: .PDFViewPageChanged, object: pdfView) {
                guard let pdfView = notification.object as? PDFView,
                      let currentPage = pdfView.currentPage,
                      let pageIndex = pdfView.document?.index(for: currentPage) else { continue }

                self.currentIndex = pageIndex
                log.debug("页面变更 \(self.currentIndex)")
            }
        }
    }

    deinit {
        pageIndexTask?.cancel()
    }
}

extension PDFProxy {
    @available(iOS 11.0, *)
    @discardableResult
    func setDisplayMode(_ mode: PDFDisplayMode) -> Bool {
        guard let pdfView = pdfView else { return false }

        pdfView.displaysAsBook = false
        pdfView.scaleFactor = 1
        if let pdfPrevPageChangeSwipeGestureRecognizer = pdfTwoUpGestureRecognizer{
            pdfView.removeGestureRecognizer(pdfPrevPageChangeSwipeGestureRecognizer)
        }
        switch mode {
        case .singlePage:
            pdfView.usePageViewController(true, withViewOptions: nil)
        case .singlePageContinuous:
            pdfView.usePageViewController(false, withViewOptions: nil)
        case .twoUp:
            pdfView.usePageViewController(false, withViewOptions: nil)
            let pdfPrevPageChangeSwipeGestureRecognizer = TwoUpGestureRecognizer(pdfView: pdfView)
            pdfView.addGestureRecognizer(pdfPrevPageChangeSwipeGestureRecognizer)
            self.pdfTwoUpGestureRecognizer = pdfPrevPageChangeSwipeGestureRecognizer
        case .twoUpContinuous:
            pdfView.usePageViewController(false, withViewOptions: nil)
        @unknown default:
            #if DEBUG
                fatalError("未知 PDFDisplayMode")
            #else
                return false
            #endif
        }
        
        pdfView.displayMode = mode
        setAutoScales(true)
        
        return pdfView.displayMode == mode
    }

    /// 设置 PDFView 的翻页方向
    ///
    /// - Parameter direction: 翻页方向，类型为 `PDFDisplayDirection`
    ///   - `.vertical`：纵向翻页
    ///   - `.horizontal`：横向翻页
    /// - Returns: 返回 Bool，表示是否成功修改翻页方向
    @discardableResult
    func setDisplayDirection(_ direction: PDFDisplayDirection) -> Bool {
        guard let pdfView = pdfView, pdfView.displayDirection != direction else { return false }
        pdfView.displayDirection = direction
        return true
    }

    /// 设置 PDFView 是否自动缩放以适应页面大小
    ///
    /// - Parameter enabled: true 表示自动缩放，false 表示不自动缩放
    /// - Returns: 返回 Bool，表示是否成功修改设置
    @discardableResult
    func setAutoScales(_ enabled: Bool) -> Bool {
        guard let pdfView = pdfView, pdfView.autoScales != enabled else { return false }
        pdfView.autoScales = enabled
        return true
    }

    // MARK: - 缩放函数

    /// 放大 PDF 页面
    ///
    /// - Returns: 返回 Bool，表示是否成功执行放大操作
    @discardableResult
    func zoomIn() -> Bool {
        guard let pdfView = pdfView, pdfView.canZoomIn else { return false }
        pdfView.zoomIn(nil)
        return true
    }

    /// 缩小 PDF 页面
    ///
    /// - Returns: 返回 Bool，表示是否成功执行缩小操作
    @discardableResult
    func zoomOut() -> Bool {
        guard let pdfView = pdfView, pdfView.canZoomOut else { return false }
        pdfView.zoomOut(nil)
        return true
    }

    /// 设置 PDF 页面缩放比例
    ///
    /// - Parameter factor: 缩放比例
    /// - Returns: 返回 Bool，表示是否成功修改缩放比例
    @discardableResult
    func setScaleFactor(_ factor: CGFloat) -> Bool {
        guard let pdfView = pdfView, pdfView.scaleFactor != factor else { return false }
        pdfView.scaleFactor = factor
        return true
    }

    // MARK: - 页面导航函数

    /// 跳转到指定页
    ///
    /// - Parameter index: 目标页索引（从 0 开始）
    /// - Returns: 返回 Bool，表示是否成功跳转
    ///   - 如果索引无效或当前页已是目标页，则返回 false
    @discardableResult
    func goToPage(_ index: Int) -> Bool {
        guard let pdfView = pdfView, let doc = pdfView.document, index >= 0, index < doc.pageCount else { return false }
        if let currentPage = pdfView.currentPage, doc.index(for: currentPage) == index { return false }
        if let page = doc.page(at: index) {
            pdfView.go(to: page)
            return true
        }
        return false
    }

    /// 获取当前 PDF 页面索引
    ///
    /// - Returns: 当前页索引，从 0 开始。如果获取失败，返回 0
    private func setCurrentPageIndex() -> Int {
        guard let pdfView = pdfView, let doc = pdfView.document, let page = pdfView.currentPage else { return 0 }
        return doc.index(for: page)
    }

    /// 设置页边距
    @discardableResult
    func setPageBreakMargins(_ margins: UIEdgeInsets) -> Bool {
        guard let pdfView = pdfView, pdfView.pageBreakMargins != margins else { return false }
        pdfView.pageBreakMargins = margins
        return true
    }

    /// 设置渲染时使用的页面区域（CropBox、MediaBox 等）
    @discardableResult
    func setDisplayBox(_ box: PDFDisplayBox) -> Bool {
        guard let pdfView = pdfView, pdfView.displayBox != box else { return false }
        pdfView.displayBox = box
        return true
    }

    /// 设置右到左显示（适用于书籍或 RTL 语言）
    @available(iOS 11.0, *)
    @discardableResult
    func setDisplaysRTL(_ enabled: Bool) -> Bool {
        guard let pdfView = pdfView, pdfView.displaysRTL != enabled else { return false }
        pdfView.displaysRTL = enabled
        return true
    }

    // MARK: - 页面视图控制方法

    /// 设置 PDFView 是否使用 PageViewController 来分页显示
    ///
    /// - Parameter enabled: `true` 使用 UIPageViewController 显示（分页效果），`false` 直接滚动显示
    /// - Returns: 返回 `true` 表示修改成功，`false` 表示 PDFView 不存在或已是该状态
    @discardableResult
    private func usePageViewController(_ enabled: Bool) -> Bool {
        guard let pdfView = pdfView, pdfView.isUsingPageViewController != enabled else { return false }
        pdfView.usePageViewController(enabled)
        return true
    }

    /// 重新布局 PDFView 中的文档视图
    /// 会重置文档位置！！！
    /// 当修改了显示模式、显示方向或分页方式后，调用此方法刷新布局
    /// - Returns: 返回 `true` 表示刷新成功，`false` 表示 PDFView 不存在
    @discardableResult
    private func layoutDocumentView() -> Bool {
        guard let pdfView = pdfView else { return false }
        pdfView.layoutDocumentView()
        return true
    }

    // MARK: - 页面分隔线设置

    /// 设置 PDFView 是否显示页面间的分隔线
    ///
    /// - Parameter enabled: `true` 显示页面分隔线，`false` 隐藏
    /// - Returns: 返回一个 Bool，表示是否成功修改了设置
    @discardableResult
    func setDisplaysPageBreaks(_ enabled: Bool) -> Bool {
        guard let pdfView = pdfView, pdfView.displaysPageBreaks != enabled else { return false }
        pdfView.displaysPageBreaks = enabled
        return true
    }

    // MARK: - 标记模式设置

    /// 设置 PDFView 是否进入标记模式（Markup Mode）
    ///
    /// - Parameter enabled: `true` 表示进入标记模式，可进行高亮、注释等操作；`false` 表示退出标记模式
    /// - Returns: 返回一个 Bool，表示是否成功修改了标记模式
    @discardableResult
    func setInMarkupMode(_ enabled: Bool) -> Bool {
        guard let pdfView = pdfView, pdfView.isInMarkupMode != enabled else { return false }
        pdfView.isInMarkupMode = enabled
        return true
    }
}

extension PDFProxy {
    /// 生成指定页的缩略图
    ///
    /// - Parameters:
    ///   - pageIndex: PDF 页索引 (0 开始)
    ///   - size: 缩略图大小
    /// - Returns: UIImage 缩略图，失败返回 nil
    func generateThumbnail(for pageIndex: Int, size: CGSize) -> UIImage? {
        guard let pdfDocument = pdfView?.document,
              pageIndex >= 0, pageIndex < pdfDocument.pageCount,
              let page = pdfDocument.page(at: pageIndex) else {
            return nil
        }

        return page.thumbnail(of: size, for: .cropBox)
    }

    /// 生成整个 PDF 的缩略图数组
    ///
    /// - Parameter size: 每页缩略图大小
    /// - Returns: [UIImage]，按页顺序排列
    func generateAllThumbnails(size: CGSize) -> [UIImage] {
        guard let pdfDocument = pdfView?.document else { return [] }
        var thumbnails: [UIImage] = []

        for i in 0 ..< pdfDocument.pageCount {
            if let thumb = pdfDocument.page(at: i)?.thumbnail(of: size, for: .cropBox) {
                thumbnails.append(thumb)
            }
        }

        return thumbnails
    }

    /// 生成指定页的缩略图结构体
    ///
    /// - Parameters:
    ///   - pageIndex: PDF 页索引 (0 开始)
    ///   - size: 缩略图大小
    /// - Returns: PDFThumbnail，失败返回 nil
    func generateThumbnailStruct(for pageIndex: Int, size: CGSize) -> PDFThumbnail? {
        guard let pdfDocument = pdfView?.document,
              pageIndex >= 0, pageIndex < pdfDocument.pageCount,
              let page = pdfDocument.page(at: pageIndex) else {
            return nil
        }

        let image = page.thumbnail(of: size, for: .cropBox)
        return PDFThumbnail(pageIndex: pageIndex, image: image)
    }

    /// 生成整个 PDF 的缩略图结构体数组
    ///
    /// - Parameter size: 每页缩略图大小
    /// - Returns: [PDFThumbnail]，按页顺序排列
    func generateAllThumbnailsStruct(size: CGSize) -> [PDFThumbnail] {
        guard let pdfDocument = pdfView?.document else { return [] }
        var thumbnails: [PDFThumbnail] = []
        for i in 0 ..< pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                let image = page.thumbnail(of: size, for: .cropBox)
                thumbnails.append(PDFThumbnail(pageIndex: i, image: image))
            }
        }
        return thumbnails
    }
}

extension PDFProxy {
    /// 获取指定页的原始尺寸
    ///
    /// - Parameter pageIndex: 页索引（0 开始）
    /// - Returns: CGSize，失败返回 nil
    func originalPageSize(at pageIndex: Int) -> CGSize? {
        guard let pdfDocument = pdfView?.document,
              pageIndex >= 0, pageIndex < pdfDocument.pageCount,
              let page = pdfDocument.page(at: pageIndex) else {
            return nil
        }

        return page.bounds(for: .cropBox).size
    }

    /// 获取整个 PDF 的所有原始页尺寸
    ///
    /// - Returns: [CGSize] 按页顺序排列
    func allPageSizes() -> [CGSize] {
        guard let pdfDocument = pdfView?.document else { return [] }
        return (0 ..< pdfDocument.pageCount).compactMap { pdfDocument.page(at: $0)?.bounds(for: .cropBox).size }
    }
}

extension PDFProxy {
    func addImage() {
        if let pdfPage = pdfView?.currentPage {
            // 定义印章的区域
            let bounds = CGRect(x: 100, y: 100, width: 150, height: 50)

            // 创建印章注释
            let stampAnnotation = PDFAnnotation(bounds: bounds,
                                                forType: .stamp,
                                                withProperties: nil)
            stampAnnotation.contents = "已批准 ✅"

            // 添加到 PDF 页面
            pdfPage.addAnnotation(stampAnnotation)
        }
    }

    func addUIImage() {
        guard let pdfPage = pdfView?.currentPage else { return }

        let bounds = CGRect(x: 100, y: 100, width: 150, height: 50)
        let annotation = ImageStampAnnotation(bounds: bounds,
                                              forType: .stamp,
                                              withProperties: nil)
        annotation.customImage = UIImage(named: "123")

        pdfPage.addAnnotation(annotation)
    }
}

class ImageStampAnnotation: PDFAnnotation {
    var customImage: UIImage?

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        super.draw(with: box, in: context)
        if let image = customImage?.cgImage {
            context.draw(image, in: bounds)
        }
    }
}
